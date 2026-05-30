using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Recommendations;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Cart.Command.UpdateCart
{
    internal sealed class UpdateCartCommandHandler : ICommandHandler<UpdateCartCommand, ShoppingCart>
    {
        private readonly ICartService _cartService;
        private readonly IBookRepository _bookRepository;
        private readonly ICartInteractionRepository _cartInteractionRepository;

        public UpdateCartCommandHandler(
            ICartService cartService,
            IBookRepository bookRepository,
            ICartInteractionRepository cartInteractionRepository)
        {
            _cartService = cartService;
            _bookRepository = bookRepository;
            _cartInteractionRepository = cartInteractionRepository;
        }

        public async Task<Result<ShoppingCart>> Handle(UpdateCartCommand request, CancellationToken cancellationToken)
        {
            var requestedCartId = request.Id.GetValueOrDefault();
            ShoppingCart? existingCart = null;

            if (requestedCartId != Guid.Empty)
            {
                existingCart = await _cartService.GetCartAsync(requestedCartId.ToString());
                if (existingCart is null)
                {
                    return Result.Failure<ShoppingCart>(new Error("Cart.NotFound", "Cart was not found."));
                }

                if (existingCart.UserId != request.UserId)
                {
                    return Result.Failure<ShoppingCart>(new Error("Cart.Forbidden", "You do not have access to this cart."));
                }
            }

            var cartId = existingCart?.Id ?? Guid.NewGuid();
            var cart = ShoppingCart.CreateCart(cartId, request.UserId);
            var distinctItems = request.Items
                .GroupBy(item => item.BookId)
                .Select(group => group.First())
                .ToList();
            var bookIds = distinctItems.Select(item => item.BookId).ToList();
            var books = await _bookRepository.GetByIdsWithDetailsAsync(bookIds, cancellationToken);
            var bookLookup = books.ToDictionary(book => book.Id);

            foreach (var item in distinctItems)
            {
                if (!bookLookup.TryGetValue(item.BookId, out var book))
                {
                    return Result.Failure<ShoppingCart>(new Error("Cart.BookNotFound", "One or more books in the cart were not found."));
                }

                cart.Items.Add(ShoppingCartItem.AddItem(
                    cartId,
                    item.BookId,
                    book.Price));
            }

            var newBookIds = distinctItems.Select(i => i.BookId).OrderBy(id => id).ToList();
            var existingBookIds = existingCart?.Items.Select(i => i.BookId).OrderBy(id => id).ToList();
            var itemsUnchanged = existingBookIds != null && newBookIds.SequenceEqual(existingBookIds);

            if (itemsUnchanged && !string.IsNullOrWhiteSpace(existingCart?.PaymentIntentId))
            {
                cart.SetPaymentIntent(existingCart.PaymentIntentId);
                cart.ClientSecret = existingCart.ClientSecret;
            }

            var updated = await _cartService.SetCartAsync(cart);
            if (updated is null)
            {
                return Result.Failure<ShoppingCart>(Error.NullValue);
            }

            // Persist a durable recommender signal for every book placed in the cart. The live
            // cart lives in Redis, so this is what the recommender reads instead of the unused
            // SQL ShoppingCarts/ShoppingCartItems tables. Best-effort: a signal-write failure
            // must never fail the cart update.
            try
            {
                await _cartInteractionRepository.RecordAddedToCartAsync(request.UserId, bookIds, cancellationToken);
            }
            catch
            {
                // Non-critical signal — swallow so the cart operation still succeeds.
            }

            return Result.Success(updated);
        }
    }
}
