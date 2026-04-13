using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Genres.Query.GetGenreById
{
    public sealed record GetGenreByIdQuery(Guid GenreId) : IQuery<GenreResponse>;
}
