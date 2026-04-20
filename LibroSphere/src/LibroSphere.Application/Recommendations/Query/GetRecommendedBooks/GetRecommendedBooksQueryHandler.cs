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
            var response = new List<RecommendedBookResponse>();
            foreach (var book in books)
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
                response.Add(new RecommendedBookResponse(
                    book.Id,
                    book.Title.Value,
                    book.Description.Value,
                    book.Price.amount,
                    book.Price.Currency.Code,
                    _bookAssetStorageService.IsManagedStorageKey(book.BookLinkovi.PdfLink)
                        ? null
                        : book.BookLinkovi.PdfLink,
                    imageLink,
                    book.AuthorId,
                    book.Author?.Name.Value ?? string.Empty));
            }

            return Result.Success(response);
        }
    }
}
