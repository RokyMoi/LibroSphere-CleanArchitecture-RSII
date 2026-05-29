using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Orders.Command.RejectRefund
{
    public sealed record RejectRefundCommand(
        Guid OrderId,
        Guid AdminUserId,
        string? Reason) : ICommand;
}
