using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Domain.Entities.WishList;
using LibroSphere.Domain.Entities.WishList.Errors;

namespace LibroSphere.Application.Wishlists.Query.GetWishlistByUserId
{
    internal sealed class GetWishlistByUserIdQueryHandler : IQueryHandler<GetWishlistByUserIdQuery, WishlistResponse>
    {
        private readonly IWishlistRepository _wishlistRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetWishlistByUserIdQueryHandler(
            IWishlistRepository wishlistRepository,
            IBookAssetStorageService bookAssetStorageService)
        {
            _wishlistRepository = wishlistRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<WishlistResponse>> Handle(GetWishlistByUserIdQuery request, CancellationToken cancellationToken)
        {
            var wishlist = await _wishlistRepository.GetByUserIdAsync(request.UserId, cancellationToken);
            if (wishlist is null)
            {
                return Result.Failure<WishlistResponse>(WishlistErrors.NotFound);
            }

            var items = new List<WishlistItemResponse>();
            foreach (var item in wishlist.Items)
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(
                    item.Book.BookLinkovi.imageLink,
                    cancellationToken);
                var reviewCount = item.Book.Reviews.Count;
                var averageRating = reviewCount == 0
                    ? 0
                    : item.Book.Reviews.Average(review => review.Rating);

                items.Add(new WishlistItemResponse(
                    item.BookId,
                    item.Book.Title.Value,
                    item.Book.Description.Value,
                    item.Book.Price.amount,
                    item.Book.Price.Currency.Code,
                    null,
                    imageLink,
                    averageRating,
                    reviewCount,
                    item.Book.AuthorId,
                    item.Book.Author?.Name.Value ?? string.Empty,
                    item.Book.BookGenres.Select(bg => bg.GenreId).ToList(),
                    item.Book.BookGenres
                        .Where(bg => bg.Genre is not null)
                        .Select(bg => bg.Genre!.Name.Value)
                        .OrderBy(name => name)
                        .ToList()));
            }

            return Result.Success(new WishlistResponse(
                wishlist.Id,
                wishlist.UserId,
                items));
        }
    }
}
