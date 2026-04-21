using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Notifications.Command.MarkAllNotificationsRead;

public sealed record MarkAllNotificationsReadCommand(Guid UserId, string? UserEmail, int Take = 100) : ICommand;
