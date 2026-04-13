using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.Common.Models;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Domain.Entities.Books;

namespace LibroSphere.Application.Books.Query.GetAllBooks
{
    internal sealed class GetAllBooksQueryHandler : IQueryHandler<GetAllBooksQuery, PagedResponse<BookResponse>>
    {
        private readonly IBookRepository _bookRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetAllBooksQueryHandler(IBookRepository bookRepository, IBookAssetStorageService bookAssetStorageService)
        {
            _bookRepository = bookRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<PagedResponse<BookResponse>>> Handle(GetAllBooksQuery request, CancellationToken cancellationToken)
        {
            var books = await _bookRepository.SearchAsync(request.SearchTerm, request.AuthorId, request.GenreId, cancellationToken);

            var filteredBooks = books
                .Where(book => !request.MinPrice.HasValue || book.Price.amount >= request.MinPrice.Value)
                .Where(book => !request.MaxPrice.HasValue || book.Price.amount <= request.MaxPrice.Value);

            var response = new List<BookResponse>();
            foreach (var book in filteredBooks)
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
                response.Add(new BookResponse
                {
                    bookId = book.Id,
                    Title = book.Title.Value,
                    Description = book.Description.Value,
                    amount = book.Price.amount,
                    currency = book.Price.Currency.Code,
                    pdfLink = _bookAssetStorageService.IsManagedStorageKey(book.BookLinkovi.PdfLink)
                        ? null
                        : book.BookLinkovi.PdfLink,
                    imageLink = imageLink,
                    AuthorId = book.AuthorId
                });
            }

            return Result.Success(PagedResponse<BookResponse>.Create(response, request.Page, request.PageSize));
        }
    }
}
