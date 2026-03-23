using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.WishList;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class WishlistItem:BaseEntity
    {
        private WishlistItem(Guid id, Guid wishlistId, Guid bookId) : base(id)
        {
            WishlistId = wishlistId;
            BookId = bookId;
        }

        protected WishlistItem() { }
        public Guid WishlistId { get; private set; }
        public Wishlist Wishlist { get; private set; }

        public Guid BookId { get; private set; }
        public Book Book { get; private set; }

        public static WishlistItem AddItem(Guid wishlistId, Guid bookId)
        {
            return new WishlistItem(Guid.NewGuid(), wishlistId, bookId);
        }
    }
}
