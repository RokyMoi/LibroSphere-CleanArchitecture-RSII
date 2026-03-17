using LibroSphere.Domain.Entities.Books.Events;
using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Books.Command.CreateNewBook.DomainEventHandler
{
    internal sealed class BookWasCreatedDomainHandler : INotificationHandler<BookCreatedDomainEvent>
    {
        public Task Handle(BookCreatedDomainEvent notification, CancellationToken cancellationToken)
        {
            throw new NotImplementedException();
        }
    }
}
