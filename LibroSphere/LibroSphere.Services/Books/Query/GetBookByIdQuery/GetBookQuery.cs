using LibroSphere.Application.Abstractions.Messaging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Books.Query.GetBookByIdQuery
{
   public sealed record GetBookQuery(Guid bookId):IQuery<BookResponse>;
}
