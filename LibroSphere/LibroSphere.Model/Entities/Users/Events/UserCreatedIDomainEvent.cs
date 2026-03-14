using LibroSphere.Domain.Abstraction;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Users.Events
{
    public sealed record UserCreatedIDomainEvent(Guid id):IDomainEvent
    {
    }
}
