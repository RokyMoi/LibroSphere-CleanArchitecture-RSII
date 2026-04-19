using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Authors.Errors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Genre;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace LibroSphere.Application.Books.Command.CreateNewBook
{
    internal sealed class MakeNewBookCommandHandler
        : ICommandHandler<MakeNewBookCommand, Guid>
    {
        private readonly IAuthorRepository _authorRepository;
        private readonly IGenreRepository _genreRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IBookRepository _bookRepository;

        public MakeNewBookCommandHandler(
            IAuthorRepository authorRepository,
            IGenreRepository genreRepository,
            IUnitOfWork unitOfWork,
            IBookRepository bookRepo
            ) 
        {
            _authorRepository = authorRepository;
            _genreRepository = genreRepository;
            _unitOfWork = unitOfWork;
            _bookRepository = bookRepo;
            
        }

        public async Task<Result<Guid>> Handle(
            MakeNewBookCommand request,
            CancellationToken cancellationToken)
        {
         
            var author = await _authorRepository.GetAsyncById(request.authorId);
         

            if (author == null)
            {
                return Result.Failure<Guid>(AuthorErrors.NotFound);
            }
          
           
            var book =Book.MakeABook(
                request.title,
                request.description,
                request.price,
                request.bookLinks,
                request.authorId);

            var genres = request.GenreIds.Count == 0
                ? new List<Genre>()
                : await _genreRepository.GetByIdsAsync(request.GenreIds, cancellationToken);

            _bookRepository.Add(book);
            _bookRepository.ReplaceGenres(book, genres);

            
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success(book.Id);
        }
    }
}
