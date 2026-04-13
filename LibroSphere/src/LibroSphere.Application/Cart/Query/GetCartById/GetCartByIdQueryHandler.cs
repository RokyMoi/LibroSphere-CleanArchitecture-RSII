using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Cart.Query.GetCartById
{
    internal sealed class GetCartByIdQueryHandler : IQueryHandler<GetCartByIdQuery, ShoppingCart>
    {
        private readonly ICartService _cartService;

        public GetCartByIdQueryHandler(ICartService cartService)
        {
            _cartService = cartService;
        }

        public async Task<Result<ShoppingCart>> Handle(GetCartByIdQuery request, CancellationToken cancellationToken)
        {
            var cart = await _cartService.GetCartASync(request.CartId.ToString());
            return cart is not null
                ? Result.Success(cart)
                : Result.Failure<ShoppingCart>(Error.NullValue);
        }
    }
}
