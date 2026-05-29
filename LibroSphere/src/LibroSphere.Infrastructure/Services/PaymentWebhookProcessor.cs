using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Application.Events.Order;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.ShopCart;
using LibroSphere.Infrastructure.Data;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Stripe;

namespace LibroSphere.Infrastructure.Services;

internal sealed class PaymentWebhookProcessor : IPaymentWebhookProcessor
{
    private readonly IOrderRepository _orderRepository;
    private readonly IUserBookRepository _userBookRepository;
    private readonly ICartService _cartService;
    private readonly IBookRepository _bookRepository;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<PaymentWebhookProcessor> _logger;

    public PaymentWebhookProcessor(
        IOrderRepository orderRepository,
        IUserBookRepository userBookRepository,
        ICartService cartService,
        IBookRepository bookRepository,
        IPublishEndpoint publishEndpoint,
        IUnitOfWork unitOfWork,
        ILogger<PaymentWebhookProcessor> logger)
    {
        _orderRepository = orderRepository;
        _userBookRepository = userBookRepository;
        _cartService = cartService;
        _bookRepository = bookRepository;
        _publishEndpoint = publishEndpoint;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<Result> ProcessAsync(string json, string signature, string webhookSecret, CancellationToken cancellationToken = default)
    {
        Stripe.Event stripeEvent;
        try
        {
            stripeEvent = EventUtility.ConstructEvent(json, signature, webhookSecret, throwOnApiVersionMismatch: false);
        }
        catch (StripeException ex)
        {
            return Result.Failure(new Error("Stripe.Webhook.Invalid", ex.Message));
        }

        switch (stripeEvent.Type)
        {
            case "payment_intent.succeeded":
                return await HandleSucceeded(stripeEvent.Data.Object as PaymentIntent, cancellationToken);
            case "payment_intent.payment_failed":
                await HandleFailed(stripeEvent.Data.Object as PaymentIntent, cancellationToken);
                break;
        }

        return Result.Success();
    }

    private async Task<Result> HandleSucceeded(PaymentIntent? intent, CancellationToken cancellationToken)
    {
        if (intent is null)
            return Result.Failure(new Error("Stripe.Webhook.InvalidPayload", "PaymentIntent payload was missing."));

        intent.Metadata.TryGetValue("cartId", out var cartId);
        var order = await _orderRepository.GetByPaymentIntentIdAsync(intent.Id, cancellationToken);
        if (order is null)
        {
            var orderResult = await CreateOrderFromPaymentIntentAsync(intent, cartId, cancellationToken);
            if (orderResult.IsFailure)
                return Result.Failure(orderResult.Error);
            order = orderResult.Value;
        }

        var alreadyProcessed = order.Status == OrderStatus.PaymentReceived;
        order.UpdateStatus(OrderStatus.PaymentReceived);

        // Persist the status transition (and, on the create path, the new order row) in its OWN
        // transaction. Library access is granted separately below so that a duplicate UserBook
        // conflict can never roll the order status back to Pending.
        try
        {
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException ex) when (DbExceptions.IsDuplicateKeyViolation(ex))
        {
            // A concurrent delivery (e.g. Stripe retry or a second webhook sender) already
            // persisted this order. The status transition is idempotent, so this is safe.
            _logger.LogWarning(
                "Duplicate-key conflict persisting order for PaymentIntent {PaymentIntentId} — a concurrent delivery won; continuing.",
                intent.Id);
        }

        if (!alreadyProcessed)
        {
            await GrantLibraryAccessAsync(order, cancellationToken);
        }

        // FIX 3 — side effects isolated: a Redis or RabbitMQ hiccup must NOT cause a 500
        // after the DB transaction already committed.
        if (!string.IsNullOrWhiteSpace(cartId))
        {
            try { await _cartService.DeleteCartAsync(cartId, cancellationToken); }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to delete cart {CartId} after payment — will be cleaned up on next access.", cartId);
            }
        }

        if (!alreadyProcessed)
        {
            try
            {
                await _publishEndpoint.Publish(new OrderPaidIntegrationEvent(
                    order.Id,
                    order.BuyerEmail,
                    order.TotalAmount.amount,
                    order.TotalAmount.Currency.Code,
                    order.Items
                        .Select(item => new OrderPaidItem(
                            item.Title,
                            item.Price.amount,
                            item.Price.Currency.Code,
                            item.Quantity))
                        .ToList()), cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish OrderPaidIntegrationEvent for order {OrderId}. Order is saved; event may need manual replay.", order.Id);
            }
        }

        return Result.Success();
    }

    /// <summary>
    /// Grants every purchased book to the buyer's library. Each grant is its own idempotent
    /// transaction, so a duplicate on one book never affects the others or the order status.
    /// </summary>
    private async Task GrantLibraryAccessAsync(Order order, CancellationToken cancellationToken)
    {
        var bookIds = order.Items.Select(i => i.BookId).Distinct().ToList();
        var alreadyOwned = await _userBookRepository.GetOwnedBookIdsAsync(order.UserId, bookIds, cancellationToken);

        foreach (var bookId in bookIds)
        {
            if (alreadyOwned.Contains(bookId))
            {
                continue;
            }

            await _userBookRepository.AddIfNotExistsAsync(
                UserBook.Create(order.UserId, bookId), cancellationToken);
        }
    }

    private async Task<Result<Order>> CreateOrderFromPaymentIntentAsync(
        PaymentIntent intent,
        string? cartId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(cartId) ||
            !intent.Metadata.TryGetValue("userId", out var userIdValue) ||
            !Guid.TryParse(userIdValue, out var userId) ||
            !intent.Metadata.TryGetValue("buyerEmail", out var buyerEmail) ||
            string.IsNullOrWhiteSpace(buyerEmail))
        {
            return Result.Failure<Order>(new Error("Stripe.Webhook.MissingMetadata", "Payment intent metadata is incomplete."));
        }

        var cart = await _cartService.GetCartAsync(cartId, cancellationToken);
        if (cart is null)
        {
            return Result.Failure<Order>(new Error("Stripe.Webhook.CartNotFound", "Cart from payment intent metadata was not found."));
        }

        if (cart.UserId != userId)
        {
            return Result.Failure<Order>(new Error("Stripe.Webhook.CartForbidden", "Cart does not belong to payment intent user."));
        }

        var bookIds = cart.Items.Select(i => i.BookId).Distinct().ToList();
        var books = await _bookRepository.GetByIdsWithDetailsAsync(bookIds, cancellationToken);
        var bookLookup = books.ToDictionary(b => b.Id);

        var orderItems = new List<OrderItem>();
        foreach (var item in cart.Items)
        {
            if (!bookLookup.TryGetValue(item.BookId, out var book))
            {
                return Result.Failure<Order>(new Error("Stripe.Webhook.BookNotFound", $"Book {item.BookId} was not found."));
            }

            orderItems.Add(OrderItem.Create(
                book.Id,
                book.Title.Value,
                book.BookLinkovi.imageLink,
                book.Price,
                quantity: 1));
        }

        var order = Order.Create(
            userId,
            buyerEmail,
            orderItems,
            intent.Id,
            cart.ClientSecret ?? string.Empty);

        await _orderRepository.AddAsync(order, cancellationToken);
        return Result.Success(order);
    }

    private async Task HandleFailed(PaymentIntent? intent, CancellationToken cancellationToken)
    {
        if (intent is null)
        {
            return;
        }

        var order = await _orderRepository.GetByPaymentIntentIdAsync(intent.Id, cancellationToken);
        if (order is null)
        {
            return;
        }

        order.UpdateStatus(OrderStatus.PaymentFailed);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
