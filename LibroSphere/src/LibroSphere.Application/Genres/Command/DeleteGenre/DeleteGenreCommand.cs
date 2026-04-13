using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Genres.Command.DeleteGenre
{
    public sealed record DeleteGenreCommand(Guid GenreId) : ICommand;
}
