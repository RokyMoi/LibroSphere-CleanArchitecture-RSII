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
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(item.Book.BookLinkovi.imageLink, cancellationToken);
                items.Add(new WishlistItemResponse(item.BookId, item.Book.Title.Value, imageLink));
            }

            return Result.Success(new WishlistResponse(
                wishlist.Id,
                wishlist.UserId,
                items));
        }
    }
}
