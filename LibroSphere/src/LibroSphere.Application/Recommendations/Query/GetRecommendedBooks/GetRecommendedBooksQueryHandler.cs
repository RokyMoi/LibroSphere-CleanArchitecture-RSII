using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Recommendations;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Domain.Entities.Reviews;

namespace LibroSphere.Application.Recommendations.Query.GetRecommendedBooks
{
    internal sealed class GetRecommendedBooksQueryHandler : IQueryHandler<GetRecommendedBooksQuery, List<RecommendedBookResponse>>
    {
        private readonly IBookRecommendationService _recommendationService;
        private readonly IReviewRepository _reviewRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetRecommendedBooksQueryHandler(
            IBookRecommendationService recommendationService,
            IReviewRepository reviewRepository,
            IBookAssetStorageService bookAssetStorageService)
        {
            _recommendationService = recommendationService;
            _reviewRepository = reviewRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<List<RecommendedBookResponse>>> Handle(GetRecommendedBooksQuery request, CancellationToken cancellationToken)
        {
            var books = await _recommendationService.GetRecommendationsForUserAsync(request.UserId, request.Take, cancellationToken);
            var isPersonalized = books.Count > 0;
            var bookIds = books.Select(b => b.Id).ToList();
            var reviewStats = await _reviewRepository.GetStatsForBooksAsync(bookIds, cancellationToken);

            var response = await Task.WhenAll(books.Select(async book =>
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
                var stats = reviewStats.TryGetValue(book.Id, out var s) ? s : new BookReviewStats(0, 0);

                var reason = isPersonalized
                    ? "Recommended based on your reading history and preferences"
                    : "Popular among readers";

                return new RecommendedBookResponse(
                    book.Id,
                    book.Title.Value,
                    book.Description.Value,
                    book.Price.amount,
                    book.Price.Currency.Code,
                    _bookAssetStorageService.IsManagedStorageKey(book.BookLinkovi.PdfLink)
                        ? null
                        : book.BookLinkovi.PdfLink,
                    imageLink,
                    stats.Average,
                    stats.Count,
                    book.AuthorId,
                    book.Author?.Name.Value ?? string.Empty,
                    reason);
            }));

            return Result.Success(response.ToList());
        }
    }
}
