using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Authors.Errors;
using LibroSphere.Domain.Entities.Books;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace LibroSphere.Application.Books.Command.CreateNewBook
{
    internal sealed class MakeNewBookCommandHandler
        : ICommandHandler<MakeNewBookCommand, Guid>
    {
        private readonly IAuthorRepository _authorRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IBookRepository _bookRepository;

        public MakeNewBookCommandHandler(
            IAuthorRepository authorRepository,
            IUnitOfWork unitOfWork,
            IBookRepository bookRepo
            ) 
        {
            _authorRepository = authorRepository;
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

       
           _bookRepository.Add(book);

            
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success(book.Id);
        }
    }
}