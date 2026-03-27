using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Users;
using System;
using System.Collections.Generic;

namespace LibroSphere.Domain.Entities.ShopCart
{
    public class ShoppingCart : BaseEntity
    {
        private ShoppingCart(Guid id, Guid userId) : base(id)
        {
            UserId = userId;
            Items = new List<ShoppingCartItem>();
        }
        protected ShoppingCart() { }

        public Guid UserId { get; private set; }
        public User User { get; private set; }

        public ICollection<ShoppingCartItem> Items { get; private set; }

        public static ShoppingCart CreateCart(Guid userId)
        {
            return new ShoppingCart(Guid.NewGuid(), userId);
        }
    }
}