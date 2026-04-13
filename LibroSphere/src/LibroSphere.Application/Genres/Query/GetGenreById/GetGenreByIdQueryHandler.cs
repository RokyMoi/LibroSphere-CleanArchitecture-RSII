using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.Books.Genre.Errors;

namespace LibroSphere.Application.Genres.Query.GetGenreById
{
    internal sealed class GetGenreByIdQueryHandler : IQueryHandler<GetGenreByIdQuery, GenreResponse>
    {
        private readonly IGenreRepository _genreRepository;

        public GetGenreByIdQueryHandler(IGenreRepository genreRepository)
        {
            _genreRepository = genreRepository;
        }

        public async Task<Result<GenreResponse>> Handle(GetGenreByIdQuery request, CancellationToken cancellationToken)
        {
            var genre = await _genreRepository.GetAsyncById(request.GenreId, cancellationToken);
            if (genre is null)
            {
                return Result.Failure<GenreResponse>(GenreErrors.NotFound);
            }

            return Result.Success(new GenreResponse(genre.Id, genre.Name.Value));
        }
    }
}
