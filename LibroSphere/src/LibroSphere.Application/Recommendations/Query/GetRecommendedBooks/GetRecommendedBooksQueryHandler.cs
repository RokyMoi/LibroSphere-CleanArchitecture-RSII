using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Recommendations;
using LibroSphere.Application.Abstractions.Storage;

namespace LibroSphere.Application.Recommendations.Query.GetRecommendedBooks
{
    internal sealed class GetRecommendedBooksQueryHandler : IQueryHandler<GetRecommendedBooksQuery, List<RecommendedBookResponse>>
    {
        private readonly IBookRecommendationService _recommendationService;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetRecommendedBooksQueryHandler(
            IBookRecommendationService recommendationService,
            IBookAssetStorageService bookAssetStorageService)
        {
            _recommendationService = recommendationService;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<List<RecommendedBookResponse>>> Handle(GetRecommendedBooksQuery request, CancellationToken cancellationToken)
        {
            var books = await _recommendationService.GetRecommendationsForUserAsync(request.UserId, request.Take, cancellationToken);
            var response = await Task.WhenAll(books.Select(async book =>
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
                var reviewCount = book.Reviews.Count;
                var averageRating = reviewCount == 0
                    ? 0
                    : book.Reviews.Average(review => review.Rating);

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
                    averageRating,
                    reviewCount,
                    book.AuthorId,
                    book.Author?.Name.Value ?? string.Empty);
            }));

            return Result.Success(response.ToList());
        }
    }
}
