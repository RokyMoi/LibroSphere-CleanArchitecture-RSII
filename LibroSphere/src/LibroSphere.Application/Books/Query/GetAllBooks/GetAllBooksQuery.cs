using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Books.Query.GetAllBooks
{
    public sealed record GetAllBooksQuery(string? SearchTerm = null, Guid? AuthorId = null, Guid? GenreId = null) : IQuery<List<LibroSphere.Application.Books.Query.GetBookByIdQuery.BookResponse>>;
}
