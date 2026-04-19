using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Books.Events;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.Shared;

namespace LibroSphere.Domain.Entities.Books
{
    public class Book : BaseEntity
    {
        private Book(
            Guid id,
            Title title,
            Description description,
            Money price,
            BookLinks bookLinks,
            Guid authorId) : base(id)
        {
            Title = title;
            Description = description;
            Price = price;
            BookLinkovi = bookLinks;
            AuthorId = authorId;

            BookGenres = new List<BookGenre>();
            Reviews = new List<Review>();
            ShoppingCartItems = new List<ShoppingCartItem>();
            WishlistItems = new List<WishlistItem>();
            UserBooks = new List<UserBook>();
        }

        protected Book()
        {
            BookGenres = new List<BookGenre>();
            Reviews = new List<Review>();
            ShoppingCartItems = new List<ShoppingCartItem>();
            WishlistItems = new List<WishlistItem>();
            UserBooks = new List<UserBook>();
        }

        public Title Title { get; private set; } = null!;
        public Description Description { get; private set; } = null!;
        public Money Price { get; private set; } = null!;
        public BookLinks BookLinkovi { get; private set; } = null!;
        public Guid AuthorId { get; private set; }
        public Author Author { get; private set; } = null!;
        public ICollection<BookGenre> BookGenres { get; private set; }
        public ICollection<Review> Reviews { get; private set; }
        public ICollection<ShoppingCartItem> ShoppingCartItems { get; private set; }
        public ICollection<WishlistItem> WishlistItems { get; private set; }
        public ICollection<UserBook> UserBooks { get; private set; }

        public static Book MakeABook(
            Title title,
            Description description,
            Money price,
            BookLinks bookLinks,
            Guid authorId)
        {
            var book = new Book(Guid.NewGuid(), title, description, price, bookLinks, authorId);
            book.RaiseDomainEvent(new BookCreatedDomainEvent(book.Id, book.Title.Value, book.AuthorId, book.Price.amount, book.Price.Currency.Code));
            return book;
        }

        public void Update(
            Title title,
            Description description,
            Money price,
            BookLinks bookLinks,
            Guid authorId)
        {
            Title = title;
            Description = description;
            Price = price;
            BookLinkovi = bookLinks;
            AuthorId = authorId;
            RaiseDomainEvent(new BookUpdatedDomainEvent(Id, Title.Value, AuthorId, Price.amount, Price.Currency.Code));
        }

        public void MarkAsDeleted()
        {
            RaiseDomainEvent(new BookDeletedDomainEvent(Id, Title.Value, AuthorId));
        }
    }
}
