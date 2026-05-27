using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany.Events;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class UserBook : BaseEntity
    {
        private UserBook(Guid id, Guid userId, Guid bookId, DateTime purchasedAt)
            : base(id)
        {
            UserId = userId;
            BookId = bookId;
            PurchasedAt = purchasedAt;
        }

        protected UserBook()
        {
        }

        public Guid UserId { get; private set; }
        public User User { get; private set; } = null!;
        public Guid BookId { get; private set; }
        public Book Book { get; private set; } = null!;
        public DateTime PurchasedAt { get; private set; }

        public static UserBook Create(Guid userId, Guid bookId)
        {
            var userBook = new UserBook(Guid.NewGuid(), userId, bookId, DateTime.UtcNow);
            userBook.RaiseDomainEvent(new UserBookGrantedDomainEvent(userBook.Id, userBook.UserId, userBook.BookId));
            return userBook;
        }
    }
}
