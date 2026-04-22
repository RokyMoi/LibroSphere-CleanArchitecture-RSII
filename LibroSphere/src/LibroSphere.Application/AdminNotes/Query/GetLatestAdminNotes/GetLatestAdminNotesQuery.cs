using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;

namespace LibroSphere.Application.AdminNotes.Query.GetLatestAdminNotes;

public sealed record GetLatestAdminNotesQuery(int Take = 20)
    : IQuery<IReadOnlyCollection<AdminNoteDto>>;
