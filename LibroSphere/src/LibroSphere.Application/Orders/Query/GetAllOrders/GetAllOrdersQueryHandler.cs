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

        var (orders, totalCount) = await _orderService.GetPagedAllOrdersAsync(
            request.SearchTerm,
            request.Status,
            page,
            pageSize,
            cancellationToken);

        var dtos = orders
            .Select(OrderListItemResponse.FromOrder)
            .ToList();

        return Result.Success(new PagedResponse<OrderListItemResponse>(dtos, page, pageSize, totalCount));
    }
}
