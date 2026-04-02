using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class UserBook : BaseEntity
    {
        private UserBook(Guid id, string userEmail, Guid bookId, DateTime purchasedAt)
            : base(id)
        {
            UserEmail = userEmail;
            BookId = bookId;
            PurchasedAt = purchasedAt;
        }

        protected UserBook() { }

        public string UserEmail { get; private set; }
        public Guid BookId { get; private set; }
        public Book Book { get; private set; }
        public DateTime PurchasedAt { get; private set; }

        public static UserBook Create(string userEmail, Guid bookId)
            => new(Guid.NewGuid(), userEmail, bookId, DateTime.UtcNow);
    }
}