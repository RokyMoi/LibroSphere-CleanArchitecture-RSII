using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Query.GetOrderById;

public sealed record OrderDetailsResponse(
    Guid Id,
    Guid UserId,
    string BuyerEmail,
    DateTime OrderDate,
    string Status,
    decimal TotalAmount,
    string Currency,
    IReadOnlyList<OrderItemResponse> Items)
{
    public static OrderDetailsResponse FromOrder(Order order) => new(
        order.Id,
        order.UserId,
        order.BuyerEmail,
        order.OrderDate,
        order.Status.ToString(),
        order.TotalAmount.amount,
        order.TotalAmount.Currency.Code,
        order.Items.Select(OrderItemResponse.FromItem).ToList());
}

public sealed record OrderItemResponse(
    Guid BookId,
    string Title,
    string ImageLink,
    decimal Price,
    string Currency,
    int Quantity)
{
    public static OrderItemResponse FromItem(OrderItem item) => new(
        item.BookId,
        item.Title,
        item.ImageLink,
        item.Price.amount,
        item.Price.Currency.Code,
        item.Quantity);
}
