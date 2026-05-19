using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Query.GetAllOrders;

public sealed record OrderListItemResponse(
    Guid Id,
    Guid UserId,
    string BuyerEmail,
    DateTime OrderDate,
    string Status,
    decimal TotalAmount,
    string Currency,
    int ItemCount)
{
    public static OrderListItemResponse FromOrder(Order order) => new(
        order.Id,
        order.UserId,
        order.BuyerEmail,
        order.OrderDate,
        order.Status.ToString(),
        order.TotalAmount.amount,
        order.TotalAmount.Currency.Code,
        order.Items.Count);
}
