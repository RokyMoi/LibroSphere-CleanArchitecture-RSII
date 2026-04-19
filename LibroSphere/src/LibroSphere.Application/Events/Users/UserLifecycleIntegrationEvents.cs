namespace LibroSphere.Application.Events.Users;

public sealed class UserLoggedInIntegrationEvent
{
    public UserLoggedInIntegrationEvent(Guid userId, string email)
    {
        UserId = userId;
        Email = email;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public UserLoggedInIntegrationEvent()
    {
        Email = string.Empty;
    }

    public Guid UserId { get; private set; }
    public string Email { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class UserDeactivatedIntegrationEvent
{
    public UserDeactivatedIntegrationEvent(Guid userId, string email)
    {
        UserId = userId;
        Email = email;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public UserDeactivatedIntegrationEvent()
    {
        Email = string.Empty;
    }

    public Guid UserId { get; private set; }
    public string Email { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}
