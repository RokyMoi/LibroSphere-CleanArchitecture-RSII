using Dapper;
using LibroSphere.Application.Abstractions.Data;
using LibroSphere.Application.Abstractions.Messaging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Metadata.Ecma335;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Books.Query.GetBookByIdQuery
{
    internal sealed class GetBookQueryHandler : IQueryHandler<GetBookQuery, BookResponse>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetBookQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<BookResponse>> Handle(GetBookQuery request, CancellationToken cancellationToken)
        {
            //We specified in using method, so our connection  will call Dipose() when handle method is finished 
            //if we can calll like that...
            using var connection = _sqlConnectionFactory.CreateConnection();

            //Dapper using, creating SQL instead of ORM - We get perfomance - and fully control on SQL Queries,
            //when days come hard
            const string sql = """
                 SELECT
                    Id,
                    Title,
                    Description,
                    PriceAmount,
                    PriceCurrency,
                    PdfLink,
                    ImageLink,
                    AuthorId
                FROM Books
                WHERE Id = @BookId
                """;

                  var book = await connection.QueryFirstOrDefaultAsync<BookResponse>(
                    sql,
                     new { BookId = request.bookId }
                     );

                   return book;
        }
        
    }
}
