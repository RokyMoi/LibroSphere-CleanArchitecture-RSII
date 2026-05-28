using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.Common.Models;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Reviews;

namespace LibroSphere.Application.Books.Query.GetAllBooks
{
    internal sealed class GetAllBooksQueryHandler : IQueryHandler<GetAllBooksQuery, PagedResponse<BookResponse>>
    {
        private readonly IBookRepository _bookRepository;
        private readonly IReviewRepository _reviewRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetAllBooksQueryHandler(
            IBookRepository bookRepository,
            IReviewRepository reviewRepository,
            IBookAssetStorageService bookAssetStorageService)
        {
            _bookRepository = bookRepository;
            _reviewRepository = reviewRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<PagedResponse<BookResponse>>> Handle(GetAllBooksQuery request, CancellationToken cancellationToken)
        {
            var page = Math.Max(1, request.Page);
            var pageSize = Math.Clamp(request.PageSize, 1, 200);

            var (pageBooks, totalCount) = await _bookRepository.SearchPagedAsync(
                request.SearchTerm,
                request.AuthorId,
                request.GenreId,
                request.MinPrice,
                request.MaxPrice,
                request.MinRating,
                page,
                pageSize,
                cancellationToken);

            var bookIds = pageBooks.Select(b => b.Id).ToList();
            var reviewStats = await _reviewRepository.GetStatsForBooksAsync(bookIds, cancellationToken);

            var response = await Task.WhenAll(pageBooks.Select(async book =>
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
                var stats = reviewStats.TryGetValue(book.Id, out var s) ? s : new BookReviewStats(0, 0);

                return new BookResponse
                {
                    bookId = book.Id,
                    Title = book.Title.Value,
                    Description = book.Description.Value,
                    amount = book.Price.amount,
                    currency = book.Price.Currency.Code,
                    imageLink = imageLink,
                    AverageRating = stats.Average,
                    ReviewCount = stats.Count,
                    AuthorId = book.AuthorId,
                    AuthorName = book.Author?.Name.Value ?? string.Empty,
                    GenreIds = book.BookGenres.Select(bg => bg.GenreId).ToList(),
                    GenreNames = book.BookGenres
                        .Where(bg => bg.Genre is not null)
                        .Select(bg => bg.Genre!.Name.Value)
                        .OrderBy(name => name)
                        .ToList()
                };
            }));

            return Result.Success(new PagedResponse<BookResponse>(
                response,
                page,
                pageSize,
                totalCount));
        }
    }
}
