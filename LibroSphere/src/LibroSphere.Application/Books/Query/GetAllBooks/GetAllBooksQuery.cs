using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;

namespace LibroSphere.Application.Books.Query.GetAllBooks
{
    public sealed record GetAllBooksQuery(
        string? SearchTerm = null,
        Guid? AuthorId = null,
        Guid? GenreId = null,
        decimal? MinPrice = null,
        decimal? MaxPrice = null,
        int Page = 1,
        int PageSize = 12) : IQuery<PagedResponse<LibroSphere.Application.Books.Query.GetBookByIdQuery.BookResponse>>;
}
