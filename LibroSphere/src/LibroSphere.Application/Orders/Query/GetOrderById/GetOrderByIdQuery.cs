using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Orders.Query.GetOrderById
{
    public sealed record GetOrderByIdQuery(Guid OrderId) : IQuery<OrderDetailsResponse>;
}
