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
        public BookGenre(Guid id) : base(id)
        {

        }
        public Guid BookId { get; private set; }
        public Book? Book { get; set; }

        public Guid GenreId { get; private set; }
        public Genre? Genre { get; private set; }
    }
}
