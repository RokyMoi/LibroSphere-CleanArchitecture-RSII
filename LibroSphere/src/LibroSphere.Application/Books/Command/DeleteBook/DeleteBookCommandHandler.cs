using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Errors;

namespace LibroSphere.Application.Books.Command.DeleteBook
{
    internal sealed class DeleteBookCommandHandler : ICommandHandler<DeleteBookCommand>
    {
        private readonly IBookRepository _bookRepository;
        private readonly IUnitOfWork _unitOfWork;

        public DeleteBookCommandHandler(IBookRepository bookRepository, IUnitOfWork unitOfWork)
        {
            _bookRepository = bookRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(DeleteBookCommand request, CancellationToken cancellationToken)
        {
            var book = await _bookRepository.GetAsyncById(request.BookId, cancellationToken);
            if (book is null)
            {
                return Result.Failure(BookErrors.NotFound);
            }

            book.MarkAsDeleted();
            _bookRepository.Delete(book);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            return Result.Success();
        }
    }
}
