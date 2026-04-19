using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books.Genre.Events;
using LibroSphere.Domain.Entities.ManyToMany;

namespace LibroSphere.Domain.Entities.Books.Genre
{
    public class Genre : BaseEntity
    {
        private Genre(Guid id, Name name) : base(id)
        {
            Name = name;
            BookGenres = new List<BookGenre>();
        }

        protected Genre()
        {
            BookGenres = new List<BookGenre>();
        }

        public Name Name { get; private set; } = null!;
        public ICollection<BookGenre> BookGenres { get; private set; }

        public static Genre Create(Name name)
        {
            var genre = new Genre(Guid.NewGuid(), name);
            genre.RaiseDomainEvent(new GenreCreatedDomainEvent(genre.Id, genre.Name.Value));
            return genre;
        }

        public void Update(Name name)
        {
            Name = name;
            RaiseDomainEvent(new GenreUpdatedDomainEvent(Id, Name.Value));
        }

        public void MarkAsDeleted()
        {
            RaiseDomainEvent(new GenreDeletedDomainEvent(Id, Name.Value));
        }
    }
}
