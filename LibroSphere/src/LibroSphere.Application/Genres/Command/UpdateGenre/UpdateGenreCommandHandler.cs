using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.Books.Genre.Errors;

namespace LibroSphere.Application.Genres.Command.UpdateGenre
{
    internal sealed class UpdateGenreCommandHandler : ICommandHandler<UpdateGenreCommand>
    {
        private readonly IGenreRepository _genreRepository;
        private readonly IUnitOfWork _unitOfWork;

        public UpdateGenreCommandHandler(IGenreRepository genreRepository, IUnitOfWork unitOfWork)
        {
            _genreRepository = genreRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(UpdateGenreCommand request, CancellationToken cancellationToken)
        {
            var genre = await _genreRepository.GetAsyncById(request.GenreId, cancellationToken);
            if (genre is null)
            {
                return Result.Failure(GenreErrors.NotFound);
            }

            var existing = await _genreRepository.GetByNameAsync(request.Name, cancellationToken);
            if (existing is not null && existing.Id != request.GenreId)
            {
                return Result.Failure(GenreErrors.AlreadyExists);
            }

            genre.Update(new Name(request.Name));
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
