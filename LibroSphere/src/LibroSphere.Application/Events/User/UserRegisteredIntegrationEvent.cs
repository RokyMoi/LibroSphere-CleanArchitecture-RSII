namespace LibroSphere.Application.Events.User;

public sealed class UserRegisteredIntegrationEvent
{
    public UserRegisteredIntegrationEvent()
    {
        FirstName = string.Empty;
        LastName = string.Empty;
        Email = string.Empty;
    }

    public UserRegisteredIntegrationEvent(
        Guid userId,
        string firstName,
        string lastName,
        string email)
    {
        UserId = userId;
        FirstName = firstName;
        LastName = lastName;
        Email = email;
    }

    public Guid UserId { get; init; }
    public string FirstName { get; init; }
    public string LastName { get; init; }
    public string Email { get; init; }
}
