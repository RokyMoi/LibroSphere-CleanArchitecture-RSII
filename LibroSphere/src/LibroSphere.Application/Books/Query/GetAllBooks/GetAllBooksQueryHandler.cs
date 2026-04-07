using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Domain.Entities.Books;

namespace LibroSphere.Application.Books.Query.GetAllBooks
{
    internal sealed class GetAllBooksQueryHandler : IQueryHandler<GetAllBooksQuery, List<BookResponse>>
    {
        private readonly IBookRepository _bookRepository;

        public GetAllBooksQueryHandler(IBookRepository bookRepository)
        {
            _bookRepository = bookRepository;
        }

        public async Task<Result<List<BookResponse>>> Handle(GetAllBooksQuery request, CancellationToken cancellationToken)
        {
            var books = await _bookRepository.SearchAsync(request.SearchTerm, request.AuthorId, request.GenreId, cancellationToken);

            var response = books.Select(book => new BookResponse
            {
                bookId = book.Id,
                Title = book.Title.Value,
                Description = book.Description.Value,
                amount = book.Price.amount,
                currency = book.Price.Currency.Code,
                pdfLink = book.BookLinkovi.PdfLink,
                imageLink = book.BookLinkovi.imageLink,
                AuthorId = book.AuthorId
            }).ToList();

            return Result.Success(response);
        }
    }
}
