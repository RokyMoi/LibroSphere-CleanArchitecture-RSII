using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Books.Command.DeleteBook
{
    public sealed record DeleteBookCommand(Guid BookId) : ICommand;
}
