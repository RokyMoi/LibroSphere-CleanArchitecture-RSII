using LibroSphere.Domain.Abstraction;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Books.Errors
{
    public static class BookErrors
    {
        public static Error NotFound = new Error("Book.NotFound", "Book with specified identifier was not found");
    }
}
