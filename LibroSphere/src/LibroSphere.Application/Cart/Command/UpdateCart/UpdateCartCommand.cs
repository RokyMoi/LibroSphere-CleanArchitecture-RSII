using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Cart.Command.UpdateCart
{
    public sealed record UpdateCartCommand(
        Guid Id,
        Guid UserId,
        string? ClientSecret,
        string? PaymentIntentId,
        List<UpdateCartItemModel> Items) : ICommand<ShoppingCart>;

    public sealed record UpdateCartItemModel(Guid BookId, decimal Amount, string CurrencyCode);
}
