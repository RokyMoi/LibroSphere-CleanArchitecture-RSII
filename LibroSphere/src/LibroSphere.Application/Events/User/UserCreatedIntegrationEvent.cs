using LibroSphere.Application.Abstractions.Events.DomainEvent;
using LibroSphere.Application.Events.IntegrationEvents;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Events.User
{
    public sealed class UserCreatedIntegrationEvent : IntegrationEvent
    {
        public UserCreatedIntegrationEvent(Guid userId, string email)
        {
            UserId = userId;
            Email = email;
        }

        public Guid UserId { get; }
        public string Email { get; }
    }
}
