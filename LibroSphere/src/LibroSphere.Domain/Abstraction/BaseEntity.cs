using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Abstraction
{
    public abstract class BaseEntity
    {
        private readonly List<IDomainEvent> _domainEvents = new List<IDomainEvent>();
        //Setter -> Init - Last for life.
        protected BaseEntity(Guid id) {
            id = id;
        }
        protected BaseEntity() { }

        public Guid Id { get; init; }

        public void ClearDomainEvents()
        {
             _domainEvents.Clear();


        }
        public IReadOnlyCollection<IDomainEvent> GetDomainEvents()
        {
                 return _domainEvents.ToList();

        }
        protected void RaiseDomainEvent(IDomainEvent domainEvent) { 
            _domainEvents.Add(domainEvent);
        }
    }
}
