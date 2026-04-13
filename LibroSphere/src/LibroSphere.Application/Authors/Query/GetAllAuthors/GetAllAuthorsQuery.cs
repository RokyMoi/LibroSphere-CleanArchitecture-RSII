using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Authors.Query.GetAuthorById;
using LibroSphere.Application.Common.Models;

namespace LibroSphere.Application.Authors.Query.GetAllAuthors
{
    public sealed record GetAllAuthorsQuery(
        string? SearchTerm = null,
        int Page = 1,
        int PageSize = 10) : IQuery<PagedResponse<AuthorResponse>>;
}
