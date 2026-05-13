using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Cart.Command.UpdateCart
{
    internal sealed class UpdateCartCommandHandler : ICommandHandler<UpdateCartCommand, ShoppingCart>
    {
        private readonly ICartService _cartService;
        private readonly IBookRepository _bookRepository;

        public UpdateCartCommandHandler(ICartService cartService, IBookRepository bookRepository)
        {
            _cartService = cartService;
            _bookRepository = bookRepository;
        }

        public async Task<Result<ShoppingCart>> Handle(UpdateCartCommand request, CancellationToken cancellationToken)
        {
            var requestedCartId = request.Id.GetValueOrDefault();
            ShoppingCart? existingCart = null;

            if (requestedCartId != Guid.Empty)
            {
                existingCart = await _cartService.GetCartASync(requestedCartId.ToString());
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
            var bookIds = request.Items
                .Select(item => item.BookId)
                .Distinct()
                .ToList();
            var books = await _bookRepository.GetByIdsWithDetailsAsync(bookIds, cancellationToken);
            var bookLookup = books.ToDictionary(book => book.Id);

            foreach (var item in request.Items)
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

            if (!string.IsNullOrWhiteSpace(existingCart?.PaymentIntentId))
            {
                cart.SetPaymentIntent(existingCart.PaymentIntentId);
                cart.ClientSecret = existingCart.ClientSecret;
            }

            var updated = await _cartService.SetCartAsync(cart);
            return updated is not null
                ? Result.Success(updated)
                : Result.Failure<ShoppingCart>(Error.NullValue);
        }
    }
}
