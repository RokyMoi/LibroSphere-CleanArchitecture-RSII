using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Query.GetAllOrders;

internal sealed class GetAllOrdersQueryHandler : IQueryHandler<GetAllOrdersQuery, PagedResponse<Order>>
{
    private readonly IOrderService _orderService;

    public GetAllOrdersQueryHandler(IOrderService orderService)
    {
        _orderService = orderService;
    }

    public async Task<Result<PagedResponse<Order>>> Handle(GetAllOrdersQuery request, CancellationToken cancellationToken)
    {
        var orders = await _orderService.GetAllOrdersAsync(cancellationToken);

        // Filter by search term (buyer email)
        if (!string.IsNullOrWhiteSpace(request.SearchTerm))
        {
            var searchTerm = request.SearchTerm.Trim().ToLowerInvariant();
            orders = orders
                .Where(o => o.BuyerEmail.ToLowerInvariant().Contains(searchTerm))
                .ToList();
        }

        // Filter by status
        if (request.Status.HasValue)
        {
            orders = orders
                .Where(o => o.Status == request.Status.Value)
                .ToList();
        }

        // Sort by created date descending (newest first)
        orders = orders
            .OrderByDescending(o => o.OrderDate)
            .ToList();

        return Result.Success(PagedResponse<Order>.Create(orders, request.Page, request.PageSize));
    }
}
