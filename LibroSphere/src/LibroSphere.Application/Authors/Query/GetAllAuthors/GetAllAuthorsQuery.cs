using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Authors.Query.GetAuthorById;

namespace LibroSphere.Application.Authors.Query.GetAllAuthors
{
    public sealed record GetAllAuthorsQuery() : IQuery<List<AuthorResponse>>;
}
