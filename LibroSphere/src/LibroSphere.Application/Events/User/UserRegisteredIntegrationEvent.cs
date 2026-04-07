namespace LibroSphere.Application.Events.User;

public sealed class UserRegisteredIntegrationEvent
{
    protected UserRegisteredIntegrationEvent()
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

    public Guid UserId { get; private set; }
    public string FirstName { get; private set; }
    public string LastName { get; private set; }
    public string Email { get; private set; }
    public string Password { get; private set; }
}
