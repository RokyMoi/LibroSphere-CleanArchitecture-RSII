using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
namespace LibroSphere.Application.Books.Query.GetBookByIdQuery
{
    public sealed class BookResponse
    {
        public Guid bookId { get; init; }
        public string Title { get; init; }
        public string Description { get; init; }
        public decimal amount{ get; init; }
        public string currency { get; init; }
        public string pdfLink { get; init; }
        public string? imageLink { get; init; }

        public Guid AuthorId { get; init; }
      
    }
}
