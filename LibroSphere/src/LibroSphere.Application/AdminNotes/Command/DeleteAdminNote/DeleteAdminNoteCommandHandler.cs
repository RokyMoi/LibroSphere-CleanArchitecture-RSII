using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.AdminNotes.Command.DeleteAdminNote;

internal sealed class DeleteAdminNoteCommandHandler
    : ICommandHandler<DeleteAdminNoteCommand>
{
    private readonly IAdminNoteService _adminNoteService;

    public DeleteAdminNoteCommandHandler(IAdminNoteService adminNoteService)
    {
        _adminNoteService = adminNoteService;
    }

    public async Task<Result> Handle(
        DeleteAdminNoteCommand request,
        CancellationToken cancellationToken)
    {
        var deleted = await _adminNoteService.DeleteAsync(request.Id, cancellationToken);

        return deleted
            ? Result.Success()
            : Result.Failure(new Error("AdminNotes.NotFound", "Admin note was not found."));
    }
}
