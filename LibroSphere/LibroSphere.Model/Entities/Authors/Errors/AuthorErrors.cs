using LibroSphere.Domain.Abstraction;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Authors.Errors
{
    public static class AuthorErrors
    {
        public static Error NotFound = new Error("Author.NFound","Author with specified identifier was not found");
    }
}
