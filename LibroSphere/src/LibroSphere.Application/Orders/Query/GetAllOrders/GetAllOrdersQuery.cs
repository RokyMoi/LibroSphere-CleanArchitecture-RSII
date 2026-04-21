using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Query.GetAllOrders;

public sealed record GetAllOrdersQuery(
    string? SearchTerm,
    OrderStatus? Status,
    int Page = 1,
    int PageSize = 20) : IQuery<PagedResponse<Order>>;
