using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.Books.Genre.Errors;

namespace LibroSphere.Application.Genres.Command.CreateGenre
{
    internal sealed class CreateGenreCommandHandler : ICommandHandler<CreateGenreCommand, Guid>
    {
        private readonly IGenreRepository _genreRepository;
        private readonly IUnitOfWork _unitOfWork;

        public CreateGenreCommandHandler(IGenreRepository genreRepository, IUnitOfWork unitOfWork)
        {
            _genreRepository = genreRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result<Guid>> Handle(CreateGenreCommand request, CancellationToken cancellationToken)
        {
            var existing = await _genreRepository.GetByNameAsync(request.Name, cancellationToken);
            if (existing is not null)
            {
                return Result.Failure<Guid>(GenreErrors.AlreadyExists);
            }

            var genre = Genre.Create(new Name(request.Name));
            _genreRepository.Add(genre);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success(genre.Id);
        }
    }
}
