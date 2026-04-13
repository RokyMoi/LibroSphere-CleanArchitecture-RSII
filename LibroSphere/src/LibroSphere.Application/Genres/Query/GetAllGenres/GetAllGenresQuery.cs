using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;

namespace LibroSphere.Application.Genres.Query.GetAllGenres
{
    public sealed record GetAllGenresQuery(
        string? SearchTerm = null,
        int Page = 1,
        int PageSize = 20) : IQuery<PagedResponse<GenreResponse>>;
}
