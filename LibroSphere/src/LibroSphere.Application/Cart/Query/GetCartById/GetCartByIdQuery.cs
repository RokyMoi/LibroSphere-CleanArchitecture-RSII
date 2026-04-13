using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Cart.Query.GetCartById
{
    public sealed record GetCartByIdQuery(Guid CartId) : IQuery<ShoppingCart>;
}
