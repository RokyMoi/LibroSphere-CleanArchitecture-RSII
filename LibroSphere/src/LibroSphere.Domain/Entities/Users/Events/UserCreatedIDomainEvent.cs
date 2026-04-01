using LibroSphere.Application.Abstractions.Events.DomainEvent;
using LibroSphere.Domain.Abstraction;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Users.Events
{
    public sealed record UserCreatedDomainEvent(Guid UserId, string Email) : IDomainEvent

    {
    }
}
