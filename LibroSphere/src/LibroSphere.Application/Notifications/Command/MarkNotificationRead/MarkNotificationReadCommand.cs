using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Notifications.Command.MarkNotificationRead;

public sealed record MarkNotificationReadCommand(Guid UserId, string NotificationId) : ICommand;
