using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany.Events;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class UserBook : BaseEntity
    {
        private UserBook(Guid id, Guid userId, string userEmail, Guid bookId, DateTime purchasedAt)
            : base(id)
        {
            UserId = userId;
            UserEmail = userEmail;
            BookId = bookId;
            PurchasedAt = purchasedAt;
        }

        protected UserBook()
        {
        }

        public Guid UserId { get; private set; }
        public User User { get; private set; } = null!;
        public string UserEmail { get; private set; } = string.Empty;
        public Guid BookId { get; private set; }
        public Book Book { get; private set; } = null!;
        public DateTime PurchasedAt { get; private set; }

        public static UserBook Create(Guid userId, string userEmail, Guid bookId)
        {
            var userBook = new UserBook(Guid.NewGuid(), userId, userEmail, bookId, DateTime.UtcNow);
            userBook.RaiseDomainEvent(new UserBookGrantedDomainEvent(userBook.Id, userBook.UserEmail, userBook.BookId));
            return userBook;
        }
    }
}
