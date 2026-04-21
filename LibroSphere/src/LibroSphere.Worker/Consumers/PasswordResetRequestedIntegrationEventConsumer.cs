using LibroSphere.Application.Events.User;
using LibroSphere.Worker.Services;
using MassTransit;

namespace LibroSphere.Worker.Consumers;

public sealed class PasswordResetRequestedIntegrationEventConsumer
    : IConsumer<PasswordResetRequestedIntegrationEvent>
{
    private readonly IEmailService _emailService;
    private readonly ILogger<PasswordResetRequestedIntegrationEventConsumer> _logger;

    public PasswordResetRequestedIntegrationEventConsumer(
        IEmailService emailService,
        ILogger<PasswordResetRequestedIntegrationEventConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<PasswordResetRequestedIntegrationEvent> context)
    {
        var message = context.Message;

        var body = $"""
                    <h2>LibroSphere - Reset lozinke</h2>
                    <p>Primili smo zahtjev za reset Vase lozinke.</p>
                    <p><strong>Vas kod:</strong> <span style="font-size:20px;">{message.Code}</span></p>
                    <p>Kod vazi {message.ExpiresInMinutes} minuta.</p>
                    <p>Ako niste zatrazili reset lozinke, ignorisite ovaj email.</p>
                    """;

        try
        {
            await _emailService.SendAsync(
                message.Email,
                "LibroSphere - Reset lozinke",
                body,
                context.CancellationToken);

            _logger.LogInformation(
                "Password reset code email sent to {Email}",
                message.Email);
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Password reset code email delivery failed for {Email}",
                message.Email);

            throw;
        }
    }
}
