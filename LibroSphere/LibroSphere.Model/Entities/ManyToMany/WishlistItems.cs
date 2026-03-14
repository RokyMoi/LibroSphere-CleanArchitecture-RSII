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
        public WishlistItem(Guid id) : base(id)
        {

        }
   
        public Guid WishlistId { get; private set; }
        public Wishlist Wishlist { get; private set; }

        public Guid BookId { get; private set; }
        public Book Book { get; private set; }
    }
}
