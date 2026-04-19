using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Authors.Events;
using LibroSphere.Domain.Entities.Books;

namespace LibroSphere.Domain.Entities.Authors
{
    public class Author : BaseEntity
    {
        private Author(Guid id, Name name, Biography biography) : base(id)
        {
            Name = name;
            Biography = biography;
            Books = new List<Book>();
        }

        protected Author()
        {
            Books = new List<Book>();
        }

        public Name Name { get; private set; } = null!;
        public Biography Biography { get; private set; } = null!;
        public ICollection<Book> Books { get; private set; }

        public static Author Create(Name name, Biography biography)
        {
            var author = new Author(Guid.NewGuid(), name, biography);
            author.RaiseDomainEvent(new AuthorCreatedDomainEvent(author.Id, author.Name.Value));
            return author;
        }

        public void Update(Name name, Biography biography)
        {
            Name = name;
            Biography = biography;
            RaiseDomainEvent(new AuthorUpdatedDomainEvent(Id, Name.Value));
        }

        public void MarkAsDeleted()
        {
            RaiseDomainEvent(new AuthorDeletedDomainEvent(Id, Name.Value));
        }
    }
}
