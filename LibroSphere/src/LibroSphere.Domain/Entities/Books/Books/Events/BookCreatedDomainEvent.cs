using LibroSphere.Application.Abstractions.Events.DomainEvent;
using LibroSphere.Domain.Abstraction;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Books.Events
{
    public sealed record BookCreatedDomainEvent(Guid BookId) : IDomainEvent;

}
