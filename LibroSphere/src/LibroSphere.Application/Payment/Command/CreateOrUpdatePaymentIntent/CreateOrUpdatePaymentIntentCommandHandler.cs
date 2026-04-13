using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Payment.Command.CreateOrUpdatePaymentIntent;

internal sealed class CreateOrUpdatePaymentIntentCommandHandler : ICommandHandler<CreateOrUpdatePaymentIntentCommand, ShoppingCart>
{
    private readonly IPaymentService _paymentService;

    public CreateOrUpdatePaymentIntentCommandHandler(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    public async Task<Result<ShoppingCart>> Handle(CreateOrUpdatePaymentIntentCommand request, CancellationToken cancellationToken)
    {
        var cart = await _paymentService.CreateOrUpdatePaymentIntent(request.CartId);

        return cart is not null
            ? Result.Success(cart)
            : Result.Failure<ShoppingCart>(new Error("Payment.Cart.Invalid", "Problem with your cart."));
    }
}
