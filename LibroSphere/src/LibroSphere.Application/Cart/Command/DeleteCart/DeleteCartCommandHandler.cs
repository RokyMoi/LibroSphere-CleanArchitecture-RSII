using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Cart.Command.DeleteCart
{
    internal sealed class DeleteCartCommandHandler : ICommandHandler<DeleteCartCommand>
    {
        private readonly ICartService _cartService;

        public DeleteCartCommandHandler(ICartService cartService)
        {
            _cartService = cartService;
        }

        public async Task<Result> Handle(DeleteCartCommand request, CancellationToken cancellationToken)
        {
            var deleted = await _cartService.DeleteCartAsync(request.CartId.ToString());
            return deleted ? Result.Success() : Result.Failure(Error.NullValue);
        }
    }
}
