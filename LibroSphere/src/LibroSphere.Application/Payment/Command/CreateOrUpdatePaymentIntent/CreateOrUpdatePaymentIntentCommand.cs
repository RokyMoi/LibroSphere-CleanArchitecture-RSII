using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Payment.Command.CreateOrUpdatePaymentIntent;

public sealed record CreateOrUpdatePaymentIntentCommand(
    string CartId,
    Guid UserId,
    string BuyerEmail) : ICommand<ShoppingCart>;
