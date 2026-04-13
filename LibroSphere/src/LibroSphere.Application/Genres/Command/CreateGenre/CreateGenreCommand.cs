using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Genres.Command.CreateGenre
{
    public sealed record CreateGenreCommand(string Name) : ICommand<Guid>;
}
