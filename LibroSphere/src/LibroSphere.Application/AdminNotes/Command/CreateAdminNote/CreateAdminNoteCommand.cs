using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;

namespace LibroSphere.Application.AdminNotes.Command.CreateAdminNote;

public sealed record CreateAdminNoteCommand(string Title, string Text, string ImageUrl)
    : ICommand<AdminNoteDto>;
