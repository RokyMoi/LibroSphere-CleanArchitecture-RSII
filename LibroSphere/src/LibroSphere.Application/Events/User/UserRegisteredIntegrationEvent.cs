namespace LibroSphere.Application.Events.User;

public sealed class UserRegisteredIntegrationEvent
{
    public UserRegisteredIntegrationEvent()
    {
        FirstName = string.Empty;
        LastName = string.Empty;
        Email = string.Empty;
        Password = string.Empty;
    }

    public UserRegisteredIntegrationEvent(
        Guid userId,
        string firstName,
        string lastName,
        string email,
        string password)
    {
        UserId = userId;
        FirstName = firstName;
        LastName = lastName;
        Email = email;
        Password = password;
    }

    public Guid UserId { get; init; }
    public string FirstName { get; init; }
    public string LastName { get; init; }
    public string Email { get; init; }
    public string Password { get; init; }
}
