using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Orders.Command.RequestRefund
{
    public sealed record RequestRefundCommand(
        Guid OrderId,
        Guid RequestingUserId,
        string? Reason) : ICommand;
}
