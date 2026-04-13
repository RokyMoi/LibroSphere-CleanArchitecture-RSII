using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.WishList;
using LibroSphere.Domain.Entities.WishList.Errors;

namespace LibroSphere.Application.Wishlists.Command.RemoveWishlistItem
{
    internal sealed class RemoveWishlistItemCommandHandler : ICommandHandler<RemoveWishlistItemCommand>
    {
        private readonly IWishlistRepository _wishlistRepository;
        private readonly LibroSphere.Domain.Abstraction.IUnitOfWork _unitOfWork;

        public RemoveWishlistItemCommandHandler(IWishlistRepository wishlistRepository, LibroSphere.Domain.Abstraction.IUnitOfWork unitOfWork)
        {
            _wishlistRepository = wishlistRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(RemoveWishlistItemCommand request, CancellationToken cancellationToken)
        {
            var wishlist = await _wishlistRepository.GetByUserIdAsync(request.UserId, cancellationToken);
            if (wishlist is null)
            {
                return Result.Failure(WishlistErrors.NotFound);
            }

            var item = await _wishlistRepository.GetItemAsync(wishlist.Id, request.BookId, cancellationToken);
            if (item is null)
            {
                return Result.Failure(WishlistErrors.BookNotInWishlist);
            }

            wishlist.RemoveItem(request.BookId);
            _wishlistRepository.RemoveItem(item);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            return Result.Success();
        }
    }
}
