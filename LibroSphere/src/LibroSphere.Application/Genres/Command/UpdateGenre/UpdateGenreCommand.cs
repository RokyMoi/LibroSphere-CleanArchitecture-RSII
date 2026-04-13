using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Genres.Command.UpdateGenre
{
    public sealed record UpdateGenreCommand(Guid GenreId, string Name) : ICommand;
}
