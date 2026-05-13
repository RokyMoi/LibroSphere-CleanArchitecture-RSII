using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Command.CreateOrder
{
    public sealed record CreateOrderCommand(string BuyerEmail, Guid UserId, string CartId) : ICommand<Order>;
}
