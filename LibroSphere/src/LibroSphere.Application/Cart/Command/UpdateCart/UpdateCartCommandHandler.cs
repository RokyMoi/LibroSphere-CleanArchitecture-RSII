using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Shared;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Cart.Command.UpdateCart
{
    internal sealed class UpdateCartCommandHandler : ICommandHandler<UpdateCartCommand, ShoppingCart>
    {
        private readonly ICartService _cartService;

        public UpdateCartCommandHandler(ICartService cartService)
        {
            _cartService = cartService;
        }

        public async Task<Result<ShoppingCart>> Handle(UpdateCartCommand request, CancellationToken cancellationToken)
        {
            var cart = ShoppingCart.CreateCart(request.Id, request.UserId);

            foreach (var item in request.Items)
            {
                cart.Items.Add(ShoppingCartItem.AddItem(
                    request.Id,
                    item.BookId,
                    new Money(item.Amount, Currency.FromCode(item.CurrencyCode))));
            }

            if (!string.IsNullOrWhiteSpace(request.PaymentIntentId))
            {
                cart.SetPaymentIntent(request.PaymentIntentId);
            }

            cart.ClientSecret = request.ClientSecret;

            var updated = await _cartService.SetCartAsync(cart);
            return updated is not null
                ? Result.Success(updated)
                : Result.Failure<ShoppingCart>(Error.NullValue);
        }
    }
}
