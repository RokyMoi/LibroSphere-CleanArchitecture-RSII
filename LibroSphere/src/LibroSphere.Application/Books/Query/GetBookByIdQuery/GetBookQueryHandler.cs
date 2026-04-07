using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Errors;

namespace LibroSphere.Application.Books.Query.GetBookByIdQuery
{
    internal sealed class GetBookQueryHandler : IQueryHandler<GetBookQuery, BookResponse>
    {
        private readonly IBookRepository _bookRepository;

        public GetBookQueryHandler(IBookRepository bookRepository)
        {
            _bookRepository = bookRepository;
        }

        public async Task<Result<BookResponse>> Handle(GetBookQuery request, CancellationToken cancellationToken)
        {
            var book = await _bookRepository.GetByIdWithDetailsAsync(request.bookId, cancellationToken);
            if (book is null)
            {
                return Result.Failure<BookResponse>(BookErrors.NotFound);
            }

            return Result.Success(new BookResponse
            {
                bookId = book.Id,
                Title = book.Title.Value,
                Description = book.Description.Value,
                amount = book.Price.amount,
                currency = book.Price.Currency.Code,
                pdfLink = book.BookLinkovi.PdfLink,
                imageLink = book.BookLinkovi.imageLink,
                AuthorId = book.AuthorId
            });
        }
    }
}
