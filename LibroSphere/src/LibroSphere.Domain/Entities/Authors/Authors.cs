using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Authors
{
    public class Author:BaseEntity
    {
      private Author(Guid id,Name name, Biography Biography) :base(id)
        { 
            this.Name = name;
            this.Biography = Biography;
        }
        protected Author() { }

        public Name Name { get; private set; }

        public Biography Biography { get; private set; }

        public ICollection<Book> Books { get; private set; }

        public static Author Create(Name Name, Biography Biography) {
            var author = new Author(Guid.NewGuid(),Name,Biography);
            return author;
        }
    }
}
