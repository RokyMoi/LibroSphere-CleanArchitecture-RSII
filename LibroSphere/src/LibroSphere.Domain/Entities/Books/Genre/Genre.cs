using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Reviews;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Books.Genre
{
    public class Genre:BaseEntity
    {
        private Genre(Guid id,
            Name name) : base(id)
        {
            Name = name;

            ICollection<BookGenre> BookGenres = new List<BookGenre>();
        }

        public Name Name { get; private set; }

        public ICollection<BookGenre> BookGenres { get; private set; }

        public static Genre Create(Name Name)
        {
            var genre = new Genre(Guid.NewGuid(), Name);
            return genre;

        }
    }
}
