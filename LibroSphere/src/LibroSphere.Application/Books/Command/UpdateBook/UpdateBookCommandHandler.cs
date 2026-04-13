using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Authors.Errors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Errors;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.ManyToMany;

namespace LibroSphere.Application.Books.Command.UpdateBook
{
    internal sealed class UpdateBookCommandHandler : ICommandHandler<UpdateBookCommand>
    {
        private readonly IBookRepository _bookRepository;
        private readonly IAuthorRepository _authorRepository;
        private readonly IGenreRepository _genreRepository;
        private readonly IUnitOfWork _unitOfWork;

        public UpdateBookCommandHandler(
            IBookRepository bookRepository,
            IAuthorRepository authorRepository,
            IGenreRepository genreRepository,
            IUnitOfWork unitOfWork)
        {
            _bookRepository = bookRepository;
            _authorRepository = authorRepository;
            _genreRepository = genreRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(UpdateBookCommand request, CancellationToken cancellationToken)
        {
            var book = await _bookRepository.GetByIdWithDetailsAsync(request.BookId, cancellationToken);
            if (book is null)
            {
                return Result.Failure(BookErrors.NotFound);
            }

            var author = await _authorRepository.GetAsyncById(request.AuthorId, cancellationToken);
            if (author is null)
            {
                return Result.Failure(AuthorErrors.NotFound);
            }

            var genres = request.GenreIds.Count == 0
                ? new List<Genre>()
                : await _genreRepository.GetByIdsAsync(request.GenreIds, cancellationToken);

            book.Update(request.Title, request.Description, request.Price, request.BookLinks, request.AuthorId);
            _bookRepository.ReplaceGenres(book, genres);

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            return Result.Success();
        }
    }
}
