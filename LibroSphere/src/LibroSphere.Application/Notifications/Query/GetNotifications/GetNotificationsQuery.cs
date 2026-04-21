using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;

namespace LibroSphere.Application.Notifications.Query.GetNotifications;

public sealed record GetNotificationsQuery(Guid UserId, string? UserEmail, int Take = 20)
    : IQuery<IReadOnlyCollection<SystemNotificationDto>>;
