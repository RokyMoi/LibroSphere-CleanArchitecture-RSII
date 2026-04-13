using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Users.Events;

public sealed class UserLoggedInDomainEvent(Guid userId, string email) : IDomainEvent
{
    public Guid UserId { get; } = userId;
    public string Email { get; } = email;
}
