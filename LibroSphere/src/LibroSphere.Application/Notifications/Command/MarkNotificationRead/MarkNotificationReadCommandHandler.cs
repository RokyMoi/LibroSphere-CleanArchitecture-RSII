using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Notifications.Command.MarkNotificationRead;

internal sealed class MarkNotificationReadCommandHandler
    : ICommandHandler<MarkNotificationReadCommand>
{
    private readonly INotificationCenterService _notificationCenterService;

    public MarkNotificationReadCommandHandler(INotificationCenterService notificationCenterService)
    {
        _notificationCenterService = notificationCenterService;
    }

    public async Task<Result> Handle(
        MarkNotificationReadCommand request,
        CancellationToken cancellationToken)
    {
        await _notificationCenterService.MarkAsReadAsync(
            request.UserId,
            request.NotificationId,
            cancellationToken);

        return Result.Success();
    }
}
