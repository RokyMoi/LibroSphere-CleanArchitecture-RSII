using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Errors;

namespace LibroSphere.Application.Books.Query.GetBookByIdQuery
{
    internal sealed class GetBookQueryHandler : IQueryHandler<GetBookQuery, BookResponse>
    {
        private readonly IBookRepository _bookRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetBookQueryHandler(IBookRepository bookRepository, IBookAssetStorageService bookAssetStorageService)
        {
            _bookRepository = bookRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<BookResponse>> Handle(GetBookQuery request, CancellationToken cancellationToken)
        {
            var book = await _bookRepository.GetByIdWithDetailsAsync(request.bookId, cancellationToken);
            if (book is null)
            {
                return Result.Failure<BookResponse>(BookErrors.NotFound);
            }

            var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
            var pdfLink = _bookAssetStorageService.IsManagedStorageKey(book.BookLinkovi.PdfLink)
                ? null
                : book.BookLinkovi.PdfLink;

            return Result.Success(new BookResponse
            {
                bookId = book.Id,
                Title = book.Title.Value,
                Description = book.Description.Value,
                amount = book.Price.amount,
                currency = book.Price.Currency.Code,
                pdfLink = pdfLink,
                imageLink = imageLink,
                AuthorId = book.AuthorId
            });
        }
    }
}
