using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Genre;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class BookGenre:BaseEntity
    {
        private BookGenre(Guid id) : base(id)
        {

        }
        protected BookGenre() { }
        public Guid BookId { get; private set; }
        public Book? Book { get; set; }

        public Guid GenreId { get; private set; }
        public Genre? Genre { get; private set; }

        public static BookGenre Create(Book book, Genre genre)
        {
            return new BookGenre(Guid.NewGuid())
            {
                Book = book,
                BookId = book.Id,
                Genre = genre,
                GenreId = genre.Id
            };
        }
    }
}
