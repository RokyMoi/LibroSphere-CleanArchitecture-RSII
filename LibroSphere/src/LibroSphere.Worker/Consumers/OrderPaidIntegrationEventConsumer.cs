using System.Text;
using LibroSphere.Application.Events.Order;
using LibroSphere.Worker.Services;
using MassTransit;

namespace LibroSphere.Worker.Consumers;

public sealed class OrderPaidIntegrationEventConsumer : IConsumer<OrderPaidIntegrationEvent>
{
    private readonly IEmailService _emailService;
    private readonly ILogger<OrderPaidIntegrationEventConsumer> _logger;

    public OrderPaidIntegrationEventConsumer(
        IEmailService emailService,
        ILogger<OrderPaidIntegrationEventConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<OrderPaidIntegrationEvent> context)
    {
        var message = context.Message;

        var itemRows = new StringBuilder();
        foreach (var item in message.Items)
        {
            itemRows.AppendLine($"<li>{item.Title} x{item.Quantity} - {item.Amount:0.00} {item.Currency}</li>");
        }

        var body = $"""
                    <h2>Potvrda narudzbe</h2>
                    <p>Vasa kupovina je uspjesno obradjena.</p>
                    <p><strong>Broj narudzbe:</strong> {message.OrderId}</p>
                    <p><strong>Ukupno:</strong> {message.TotalAmount:0.00} {message.Currency}</p>
                    <p><strong>Stavke:</strong></p>
                    <ul>
                        {itemRows}
                    </ul>
                    """;

        try
        {
            await _emailService.SendAsync(
                message.BuyerEmail,
                "LibroSphere potvrda narudzbe",
                body,
                context.CancellationToken);

            _logger.LogInformation(
                "Order confirmation email handled. OrderId={OrderId}, Email={Email}",
                message.OrderId,
                message.BuyerEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Order confirmation email delivery failed. OrderId={OrderId}, Email={Email}",
                message.OrderId,
                message.BuyerEmail);
        }
    }
}
