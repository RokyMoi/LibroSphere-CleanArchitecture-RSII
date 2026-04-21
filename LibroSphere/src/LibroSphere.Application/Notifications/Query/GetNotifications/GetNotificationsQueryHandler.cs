using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Notifications.Query.GetNotifications;

internal sealed class GetNotificationsQueryHandler
    : IQueryHandler<GetNotificationsQuery, IReadOnlyCollection<SystemNotificationDto>>
{
    private readonly INotificationCenterService _notificationCenterService;

    public GetNotificationsQueryHandler(INotificationCenterService notificationCenterService)
    {
        _notificationCenterService = notificationCenterService;
    }

    public async Task<Result<IReadOnlyCollection<SystemNotificationDto>>> Handle(
        GetNotificationsQuery request,
        CancellationToken cancellationToken)
    {
        var notifications = await _notificationCenterService.GetNotificationsAsync(
            request.UserId,
            request.UserEmail,
            request.Take,
            cancellationToken);

        return Result.Success(notifications);
    }
}
