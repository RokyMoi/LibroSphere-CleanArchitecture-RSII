using Dapper;
using LibroSphere.Application.Abstractions.Data;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Authors.Query.GetAuthorById
{
    internal sealed class GetAuthorByIdQueryHandler : IQueryHandler<GetAuthorByIdQuery, AuthorResponse>
    {
        public readonly ISqlConnectionFactory sqlConnectionFactory;
        public GetAuthorByIdQueryHandler(ISqlConnectionFactory _sqlconnection)
        {
            sqlConnectionFactory = _sqlconnection;
        }

        public async Task<Result<AuthorResponse>> Handle(GetAuthorByIdQuery request, CancellationToken cancellationToken)
        {
          using var connection = sqlConnectionFactory.CreateConnection();
            const string sql = """
                 SELECT
                  Id,
                  Name,
                  Biography
                FROM Author
                WHERE Id = @Parameter
                """;

            var author = await connection.QueryFirstOrDefaultAsync<AuthorResponse>(
                  sql,
                   new { Parameter = request.autorId }
                   );

            return author;

        }
    }
}
