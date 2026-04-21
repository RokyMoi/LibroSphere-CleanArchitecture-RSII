using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Notifications.Command.MarkAllNotificationsRead;

internal sealed class MarkAllNotificationsReadCommandHandler
    : ICommandHandler<MarkAllNotificationsReadCommand>
{
    private readonly INotificationCenterService _notificationCenterService;

    public MarkAllNotificationsReadCommandHandler(INotificationCenterService notificationCenterService)
    {
        _notificationCenterService = notificationCenterService;
    }

    public async Task<Result> Handle(
        MarkAllNotificationsReadCommand request,
        CancellationToken cancellationToken)
    {
        await _notificationCenterService.MarkAllAsReadAsync(
            request.UserId,
            request.UserEmail,
            request.Take,
            cancellationToken);

        return Result.Success();
    }
}
