namespace LibroSphere.Application.Events.User;

public sealed class PasswordResetRequestedIntegrationEvent
{
    public PasswordResetRequestedIntegrationEvent()
    {
        Email = string.Empty;
        Code = string.Empty;
    }

    public PasswordResetRequestedIntegrationEvent(string email, string code, int expiresInMinutes)
    {
        Email = email;
        Code = code;
        ExpiresInMinutes = expiresInMinutes;
    }

    public string Email { get; init; }
    public string Code { get; init; }
    public int ExpiresInMinutes { get; init; }
}
