using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Orders;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class OrderItem:BaseEntity
    {
        public OrderItem(Guid id) : base(id)
        {

        }
       

        public Guid OrderId { get; private set; }
        public Order Order { get; private set; }

        public Guid BookId { get; private set; }
        public Book Book { get; private set; }

        public decimal Price { get; private set; }
    }
}
