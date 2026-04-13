using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Domain.Entities.Books.Genre;

namespace LibroSphere.Application.Genres.Query.GetAllGenres
{
    internal sealed class GetAllGenresQueryHandler : IQueryHandler<GetAllGenresQuery, PagedResponse<GenreResponse>>
    {
        private readonly IGenreRepository _genreRepository;

        public GetAllGenresQueryHandler(IGenreRepository genreRepository)
        {
            _genreRepository = genreRepository;
        }

        public async Task<Result<PagedResponse<GenreResponse>>> Handle(GetAllGenresQuery request, CancellationToken cancellationToken)
        {
            var genres = await _genreRepository.GetAllAsync(cancellationToken);
            var response = genres
                .Where(x => string.IsNullOrWhiteSpace(request.SearchTerm) ||
                            x.Name.Value.Contains(request.SearchTerm, StringComparison.OrdinalIgnoreCase))
                .Select(x => new GenreResponse(x.Id, x.Name.Value))
                .ToList();

            return Result.Success(PagedResponse<GenreResponse>.Create(response, request.Page, request.PageSize));
        }
    }
}
