namespace LibroSphere.Application.Events.User;

public sealed class PasswordResetRequestedIntegrationEvent
{
    public PasswordResetRequestedIntegrationEvent()
    {
        Email = string.Empty;
    }

    public PasswordResetRequestedIntegrationEvent(string email, int expiresInMinutes)
    {
        Email = email;
        ExpiresInMinutes = expiresInMinutes;
    }

    public string Email { get; init; }
    public int ExpiresInMinutes { get; init; }
}
