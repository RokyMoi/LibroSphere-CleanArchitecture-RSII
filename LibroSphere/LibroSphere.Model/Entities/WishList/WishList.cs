using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Users;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.WishList
{
    public class Wishlist:BaseEntity
    {
        public Wishlist(Guid id):base(id)
        { }
    

        public Guid UserId { get; private set; }
        public User User { get; private set; }

        public ICollection<WishlistItem> Items { get; private set; }
    }
}
