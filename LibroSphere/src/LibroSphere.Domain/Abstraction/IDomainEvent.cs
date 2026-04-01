using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Events.DomainEvent
{
    using MediatR;

   

    public interface IDomainEvent : INotification  
    {
    }
}
