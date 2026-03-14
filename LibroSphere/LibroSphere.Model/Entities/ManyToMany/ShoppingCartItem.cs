using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ShoppingCarts;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class ShoppingCartItem:BaseEntity
    {
        public ShoppingCartItem(Guid id) : base(id)
        {

        }
   

        public Guid CartId { get; private set; }
        public ShoppingCart Cart { get; private set; }

        public Guid BookId { get; private set; }
        public Book Book { get; private set; }

        public decimal Price { get; private set; }
    }
}
