using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.AdminNotes.Query.GetLatestAdminNotes;

internal sealed class GetLatestAdminNotesQueryHandler
    : IQueryHandler<GetLatestAdminNotesQuery, IReadOnlyCollection<AdminNoteDto>>
{
    private readonly IAdminNoteService _adminNoteService;

    public GetLatestAdminNotesQueryHandler(IAdminNoteService adminNoteService)
    {
        _adminNoteService = adminNoteService;
    }

    public async Task<Result<IReadOnlyCollection<AdminNoteDto>>> Handle(
        GetLatestAdminNotesQuery request,
        CancellationToken cancellationToken)
    {
        var items = await _adminNoteService.GetLatestAsync(request.Take, cancellationToken);
        return Result.Success(items);
    }
}
