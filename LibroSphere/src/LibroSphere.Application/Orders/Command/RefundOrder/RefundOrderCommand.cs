using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Orders.Command.RefundOrder
{
    public sealed record RefundOrderCommand(
        Guid OrderId,
        Guid RequestingUserId,
        bool IsAdmin,
        decimal? Amount,
        string? Reason) : ICommand<RefundOrderResult>;

    public sealed record RefundOrderResult(
        Guid OrderId,
        string RefundId,
        string Status,
        string Message);
}
