using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.WishList;

namespace LibroSphere.Application.Wishlists.Command.AddWishlistItem
{
    internal sealed class AddWishlistItemCommandHandler : ICommandHandler<AddWishlistItemCommand>
    {
        private readonly IWishlistRepository _wishlistRepository;
        private readonly IBookRepository _bookRepository;
        private readonly IUnitOfWork _unitOfWork;

        public AddWishlistItemCommandHandler(IWishlistRepository wishlistRepository, IBookRepository bookRepository, IUnitOfWork unitOfWork)
        {
            _wishlistRepository = wishlistRepository;
            _bookRepository = bookRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(AddWishlistItemCommand request, CancellationToken cancellationToken)
        {
            var book = await _bookRepository.GetAsyncById(request.BookId, cancellationToken);
            if (book is null)
            {
                return Result.Failure(Error.NullValue);
            }

            var wishlist = await _wishlistRepository.GetByUserIdAsync(request.UserId, cancellationToken);
            if (wishlist is null)
            {
                wishlist = Wishlist.CreateWishlist(request.UserId);
                _wishlistRepository.Add(wishlist);
            }

            var existingItem = wishlist.Items.FirstOrDefault(x => x.BookId == request.BookId);
            if (existingItem is null)
            {
                var item = wishlist.AddItem(request.BookId);
                _wishlistRepository.AddItem(item);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
