using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.Books.Genre.Errors;

namespace LibroSphere.Application.Genres.Command.DeleteGenre
{
    internal sealed class DeleteGenreCommandHandler : ICommandHandler<DeleteGenreCommand>
    {
        private readonly IGenreRepository _genreRepository;
        private readonly IUnitOfWork _unitOfWork;

        public DeleteGenreCommandHandler(IGenreRepository genreRepository, IUnitOfWork unitOfWork)
        {
            _genreRepository = genreRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(DeleteGenreCommand request, CancellationToken cancellationToken)
        {
            var genre = await _genreRepository.GetAsyncById(request.GenreId, cancellationToken);
            if (genre is null)
            {
                return Result.Failure(GenreErrors.NotFound);
            }

            genre.MarkAsDeleted();
            _genreRepository.Delete(genre);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
