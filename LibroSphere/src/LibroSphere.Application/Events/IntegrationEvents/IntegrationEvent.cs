using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Events.IntegrationEvents
{
    public abstract class IntegrationEvent : IIntegrationEvent
    {
        protected IntegrationEvent()
        {
            Id = Guid.NewGuid();
            OccurredOnUtc = DateTime.UtcNow;
        }

        public Guid Id { get; }
        public DateTime OccurredOnUtc { get; }
    }
}
