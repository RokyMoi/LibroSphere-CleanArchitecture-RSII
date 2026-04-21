namespace LibroSphere.Application.Abstractions.Notifications;

public interface INotificationCenterService
{
    Task<IReadOnlyCollection<SystemNotificationDto>> GetNotificationsAsync(Guid userId, string? userEmail, int take = 20, CancellationToken cancellationToken = default);
    Task MarkAsReadAsync(Guid userId, string notificationId, CancellationToken cancellationToken = default);
    Task MarkAllAsReadAsync(Guid userId, string? userEmail, int take = 100, CancellationToken cancellationToken = default);
}

public sealed record SystemNotificationDto(
    string Id,
    bool IsRead,
    string Title,
    string Text,
    DateTime OccurredOnUtc);
