using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Abstraction
{
    using MediatR;

    public interface IDomainEvent : INotification
    {
    }
}
