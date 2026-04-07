using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.Shared;

namespace LibroSphere.Application.Books.Command.UpdateBook
{
    public sealed record UpdateBookCommand(
        Guid BookId,
        Title Title,
        Description Description,
        Money Price,
        BookLinks BookLinks,
        Guid AuthorId,
        List<Guid> GenreIds) : ICommand;
}
