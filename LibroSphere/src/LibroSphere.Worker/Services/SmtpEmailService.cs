using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;

namespace LibroSphere.Worker.Services;

internal sealed class SmtpEmailService : IEmailService
{
    private readonly SmtpEmailOptions _options;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(
        IOptions<SmtpEmailOptions> options,
        ILogger<SmtpEmailService> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task SendAsync(
        string toEmail,
        string subject,
        string htmlBody,
        CancellationToken cancellationToken = default)
    {
        if (!IsConfigured())
        {
            _logger.LogWarning(
                "Email settings are incomplete. Skipping email delivery to {Email}.",
                toEmail);
            return;
        }

        using var message = new MailMessage
        {
            From = new MailAddress(_options.FromEmail, _options.FromName),
            Subject = subject,
            Body = htmlBody,
            IsBodyHtml = true
        };

        message.To.Add(toEmail);

        using var client = new SmtpClient(_options.Host, _options.Port)
        {
            EnableSsl = _options.EnableSsl,
            Credentials = new NetworkCredential(_options.Username, _options.Password)
        };

        cancellationToken.ThrowIfCancellationRequested();
        await client.SendMailAsync(message, cancellationToken);
    }

    private bool IsConfigured()
    {
        return !string.IsNullOrWhiteSpace(_options.Host) &&
               !string.IsNullOrWhiteSpace(_options.Username) &&
               !string.IsNullOrWhiteSpace(_options.Password) &&
               !string.IsNullOrWhiteSpace(_options.FromEmail) &&
               !_options.Username.Contains("your-brevo", StringComparison.OrdinalIgnoreCase) &&
               !_options.Password.Contains("your-brevo", StringComparison.OrdinalIgnoreCase) &&
               !_options.FromEmail.EndsWith(".local", StringComparison.OrdinalIgnoreCase);
    }
}
