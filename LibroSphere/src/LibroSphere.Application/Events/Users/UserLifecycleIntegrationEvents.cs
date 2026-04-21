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

    public Guid UserId { get; init; }
    public string Email { get; init; }
    public DateTime OccurredOnUtc { get; init; }
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

    public Guid UserId { get; init; }
    public string Email { get; init; }
    public DateTime OccurredOnUtc { get; init; }
}
