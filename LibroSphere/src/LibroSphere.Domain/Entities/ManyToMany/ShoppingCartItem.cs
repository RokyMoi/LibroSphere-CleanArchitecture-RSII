using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Shared;
using LibroSphere.Domain.Entities.ShoppingCarts;
using System;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class ShoppingCartItem : BaseEntity
    {
        private ShoppingCartItem(Guid id, Guid cartId, Guid bookId, Money price) : base(id)
        {
            CartId = cartId;
            BookId = bookId;
            Price = price;
        }
        protected ShoppingCartItem() { }
        public Guid CartId { get; private set; }
        public ShoppingCart Cart { get; private set; }

        public Guid BookId { get; private set; }
        public Book Book { get; private set; }

        public Money Price { get; private set; }

        
        public static ShoppingCartItem AddItem(Guid cartId, Guid bookId, Money price)
        {
            return new ShoppingCartItem(Guid.NewGuid(), cartId, bookId, price);
        }
    }
}