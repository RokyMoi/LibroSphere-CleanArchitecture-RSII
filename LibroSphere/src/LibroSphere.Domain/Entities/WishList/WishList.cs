using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.WishList.Events;

namespace LibroSphere.Domain.Entities.WishList
{
    public class Wishlist : BaseEntity
    {
        private Wishlist(Guid id, Guid userId) : base(id)
        {
            UserId = userId;
            Items = new List<WishlistItem>();
        }

        protected Wishlist()
        {
            Items = new List<WishlistItem>();
        }

        public Guid UserId { get; private set; }
        public Users.User User { get; private set; } = null!;
        public ICollection<WishlistItem> Items { get; private set; }

        public static Wishlist CreateWishlist(Guid userId)
        {
            var wishlist = new Wishlist(Guid.NewGuid(), userId);
            wishlist.RaiseDomainEvent(new WishlistCreatedDomainEvent(wishlist.Id, wishlist.UserId));
            return wishlist;
        }

        public WishlistItem AddItem(Guid bookId)
        {
            var existing = Items.FirstOrDefault(item => item.BookId == bookId);
            if (existing is not null)
            {
                return existing;
            }

            var item = WishlistItem.AddItem(Id, bookId);
            Items.Add(item);
            RaiseDomainEvent(new WishlistItemAddedDomainEvent(Id, UserId, bookId));
            return item;
        }

        public bool RemoveItem(Guid bookId)
        {
            var item = Items.FirstOrDefault(x => x.BookId == bookId);
            if (item is null)
            {
                return false;
            }

            Items.Remove(item);
            RaiseDomainEvent(new WishlistItemRemovedDomainEvent(Id, UserId, bookId));
            return true;
        }
    }
}
