using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.WishList;
using LibroSphere.Domain.Entities.WishList.Errors;

namespace LibroSphere.Application.Wishlists.Query.GetWishlistByUserId
{
    internal sealed class GetWishlistByUserIdQueryHandler : IQueryHandler<GetWishlistByUserIdQuery, WishlistResponse>
    {
        private readonly IWishlistRepository _wishlistRepository;
        private readonly IReviewRepository _reviewRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetWishlistByUserIdQueryHandler(
            IWishlistRepository wishlistRepository,
            IReviewRepository reviewRepository,
            IBookAssetStorageService bookAssetStorageService)
        {
            _wishlistRepository = wishlistRepository;
            _reviewRepository = reviewRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<WishlistResponse>> Handle(GetWishlistByUserIdQuery request, CancellationToken cancellationToken)
        {
            var wishlist = await _wishlistRepository.GetByUserIdAsync(request.UserId, cancellationToken);
            if (wishlist is null)
            {
                return Result.Failure<WishlistResponse>(WishlistErrors.NotFound);
            }

            var bookIds = wishlist.Items.Select(item => item.BookId).ToList();
            var reviewStats = await _reviewRepository.GetStatsForBooksAsync(bookIds, cancellationToken);

            var itemTasks = wishlist.Items.Select(async item =>
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(
                    item.Book.BookLinkovi.imageLink,
                    cancellationToken);
                var stats = reviewStats.TryGetValue(item.BookId, out var s) ? s : new BookReviewStats(0, 0);

                return new WishlistItemResponse(
                    item.BookId,
                    item.Book.Title.Value,
                    item.Book.Description.Value,
                    item.Book.Price.amount,
                    item.Book.Price.Currency.Code,
                    null,
                    imageLink,
                    stats.Average,
                    stats.Count,
                    item.Book.AuthorId,
                    item.Book.Author?.Name.Value ?? string.Empty,
                    item.Book.BookGenres.Select(bg => bg.GenreId).ToList(),
                    item.Book.BookGenres
                        .Where(bg => bg.Genre is not null)
                        .Select(bg => bg.Genre!.Name.Value)
                        .OrderBy(name => name)
                        .ToList());
            });

            var items = (await Task.WhenAll(itemTasks)).ToList();

            return Result.Success(new WishlistResponse(
                wishlist.Id,
                wishlist.UserId,
                items));
        }
    }
}
