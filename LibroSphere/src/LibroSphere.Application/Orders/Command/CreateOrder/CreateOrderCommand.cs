using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Command.CreateOrder
{
    public sealed record CreateOrderCommand(string BuyerEmail, string CartId) : ICommand<Order>;
}
