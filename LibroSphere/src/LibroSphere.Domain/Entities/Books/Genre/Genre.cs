using LibroSphere.Domain.Abstraction;
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

        public Name Name { get; private set; }
        public ICollection<BookGenre> BookGenres { get; private set; }

        public static Genre Create(Name name)
        {
            return new Genre(Guid.NewGuid(), name);
        }
    }
}
