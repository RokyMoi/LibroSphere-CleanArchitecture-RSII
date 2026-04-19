using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Application.Events.Order;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
using LibroSphere.Domain.Entities.Orders;
using MassTransit;
using Stripe;

namespace LibroSphere.Infrastructure.Services;

internal sealed class PaymentWebhookProcessor : IPaymentWebhookProcessor
{
    private readonly IOrderRepository _orderRepository;
    private readonly IUserBookRepository _userBookRepository;
    private readonly IPublishEndpoint _publishEndpoint;

    public PaymentWebhookProcessor(
        IOrderRepository orderRepository,
        IUserBookRepository userBookRepository,
        IPublishEndpoint publishEndpoint)
    {
        _orderRepository = orderRepository;
        _userBookRepository = userBookRepository;
        _publishEndpoint = publishEndpoint;
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

        var order = await _orderRepository.GetByPaymentIntentIdAsync(intent.Id);
        if (order is null)
        {
            return;
        }

        order.UpdateStatus(OrderStatus.PaymentReceived);

        foreach (var item in order.Items)
        {
            var alreadyHas = await _userBookRepository.HasAccessAsync(order.BuyerEmail, item.BookId);
            if (!alreadyHas)
            {
                await _userBookRepository.AddAsync(UserBook.Create(order.BuyerEmail, item.BookId));
            }
        }

        await _orderRepository.SaveChangesAsync();
        await _userBookRepository.SaveChangesAsync();

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
        await _orderRepository.SaveChangesAsync();
    }
}
