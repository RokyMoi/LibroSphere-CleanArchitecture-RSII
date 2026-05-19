using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;

namespace LibroSphere.Application.Orders.Query.GetAllOrders;

internal sealed class GetAllOrdersQueryHandler : IQueryHandler<GetAllOrdersQuery, PagedResponse<OrderListItemResponse>>
{
    private readonly IOrderService _orderService;

    public GetAllOrdersQueryHandler(IOrderService orderService)
    {
        _orderService = orderService;
    }

    public async Task<Result<PagedResponse<OrderListItemResponse>>> Handle(GetAllOrdersQuery request, CancellationToken cancellationToken)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var orders = await _orderService.GetAllOrdersAsync(cancellationToken);

        if (!string.IsNullOrWhiteSpace(request.SearchTerm))
        {
            var searchTerm = request.SearchTerm.Trim().ToLowerInvariant();
            orders = orders
                .Where(o => o.BuyerEmail.ToLowerInvariant().Contains(searchTerm))
                .ToList();
        }

        if (request.Status.HasValue)
        {
            orders = orders
                .Where(o => o.Status == request.Status.Value)
                .ToList();
        }

        var dtos = orders
            .OrderByDescending(o => o.OrderDate)
            .Select(OrderListItemResponse.FromOrder)
            .ToList();

        return Result.Success(PagedResponse<OrderListItemResponse>.Create(dtos, page, pageSize));
    }
}
