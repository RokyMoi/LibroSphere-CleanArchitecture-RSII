using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.AdminNotes.Command.DeleteAdminNote;

public sealed record DeleteAdminNoteCommand(string Id) : ICommand;
