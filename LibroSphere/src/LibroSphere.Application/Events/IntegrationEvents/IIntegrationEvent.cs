using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Events.IntegrationEvents
{
    public interface IIntegrationEvent
    {
        Guid Id { get; }
        DateTime OccurredOnUtc { get; }
    }
}
