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
                .Where(book => !request.MaxPrice.HasValue || book.Price.amount <= request.MaxPrice.Value)
                .ToList();

            var totalCount = filteredBooks.Count;
            var pageBooks = filteredBooks
                .Skip((request.Page - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToList();

            var response = new List<BookResponse>(pageBooks.Count);
            foreach (var book in pageBooks)
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
                var pdfLink = await _bookAssetStorageService.GetPdfReadUrlAsync(book.BookLinkovi.PdfLink, cancellationToken);
                var reviewCount = book.Reviews.Count;
                var averageRating = reviewCount == 0
                    ? 0
                    : book.Reviews.Average(review => review.Rating);

                response.Add(new BookResponse
                {
                    bookId = book.Id,
                    Title = book.Title.Value,
                    Description = book.Description.Value,
                    amount = book.Price.amount,
                    currency = book.Price.Currency.Code,
                    pdfLink = pdfLink,
                    imageLink = imageLink,
                    AverageRating = averageRating,
                    ReviewCount = reviewCount,
                    AuthorId = book.AuthorId,
                    GenreIds = book.BookGenres.Select(bg => bg.GenreId).ToList(),
                    GenreNames = book.BookGenres
                        .Where(bg => bg.Genre is not null)
                        .Select(bg => bg.Genre!.Name.Value)
                        .OrderBy(name => name)
                        .ToList()
                });
            }

            return Result.Success(new PagedResponse<BookResponse>(
                response,
                request.Page,
                request.PageSize,
                totalCount));
        }
    }
}
