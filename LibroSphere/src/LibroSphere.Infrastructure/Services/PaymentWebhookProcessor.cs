using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Application.Events.Order;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.ShopCart;
using MassTransit;
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

    public PaymentWebhookProcessor(
        IOrderRepository orderRepository,
        IUserBookRepository userBookRepository,
        ICartService cartService,
        IBookRepository bookRepository,
        IPublishEndpoint publishEndpoint,
        IUnitOfWork unitOfWork)
    {
        _orderRepository = orderRepository;
        _userBookRepository = userBookRepository;
        _cartService = cartService;
        _bookRepository = bookRepository;
        _publishEndpoint = publishEndpoint;
        _unitOfWork = unitOfWork;
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
                await HandleSucceeded(stripeEvent.Data.Object as PaymentIntent, cancellationToken);
                break;
            case "payment_intent.payment_failed":
                await HandleFailed(stripeEvent.Data.Object as PaymentIntent);
                break;
        }

        return Result.Success();
    }

    private async Task HandleSucceeded(PaymentIntent? intent, CancellationToken cancellationToken)
    {
        if (intent is null)
        {
            return;
        }

        intent.Metadata.TryGetValue("cartId", out var cartId);
        var order = await _orderRepository.GetByPaymentIntentIdAsync(intent.Id);
        if (order is null)
        {
            order = await CreateOrderFromPaymentIntentAsync(intent, cartId, cancellationToken);
            if (order is null)
            {
                return;
            }
        }

        var alreadyProcessed = order.Status == OrderStatus.PaymentReceived;

        order.UpdateStatus(OrderStatus.PaymentReceived);

        foreach (var item in order.Items)
        {
            var alreadyHas = await _userBookRepository.HasAccessAsync(order.UserId, item.BookId, cancellationToken);
            if (!alreadyHas)
            {
                await _userBookRepository.AddAsync(UserBook.Create(order.UserId, item.BookId));
            }
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        if (!string.IsNullOrWhiteSpace(cartId))
        {
            await _cartService.DeleteCartAsync(cartId);
        }

        if (alreadyProcessed)
        {
            return;
        }

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

    private async Task<Order?> CreateOrderFromPaymentIntentAsync(
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
            return null;
        }

        var cart = await _cartService.GetCartAsync(cartId);
        if (cart is null)
        {
            return null;
        }

        if (cart.UserId != userId)
        {
            return null;
        }

        var bookIds = cart.Items.Select(i => i.BookId).Distinct().ToList();
        var books = await _bookRepository.GetByIdsWithDetailsAsync(bookIds, cancellationToken);
        var bookLookup = books.ToDictionary(b => b.Id);

        var orderItems = new List<OrderItem>();
        foreach (var item in cart.Items)
        {
            if (!bookLookup.TryGetValue(item.BookId, out var book))
            {
                return null;
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

        await _orderRepository.AddAsync(order);
        return order;
    }

    private async Task HandleFailed(PaymentIntent? intent)
    {
        if (intent is null)
        {
            return;
        }

        var order = await _orderRepository.GetByPaymentIntentIdAsync(intent.Id);
        if (order is null)
        {
            return;
        }

        order.UpdateStatus(OrderStatus.PaymentFailed);
        await _unitOfWork.SaveChangesAsync();
    }
}
