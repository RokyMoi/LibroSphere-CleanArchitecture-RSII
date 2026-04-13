using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Query.GetOrderById
{
    public sealed record GetOrderByIdQuery(Guid OrderId) : IQuery<Order>;
}
