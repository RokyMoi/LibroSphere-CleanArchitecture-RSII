using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Query.GetMyOrders
{
    public sealed record GetMyOrdersQuery(
        string BuyerEmail,
        OrderStatus? Status = null,
        int Page = 1,
        int PageSize = 10) : IQuery<PagedResponse<Order>>;
}
