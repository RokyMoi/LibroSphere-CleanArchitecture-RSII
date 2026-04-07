namespace LibroSphere.Application.Events.User;

public sealed class UserRegisteredIntegrationEvent
{
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

    public Guid UserId { get; }
    public string FirstName { get; }
    public string LastName { get; }
    public string Email { get; }
    public string Password { get; }
}
