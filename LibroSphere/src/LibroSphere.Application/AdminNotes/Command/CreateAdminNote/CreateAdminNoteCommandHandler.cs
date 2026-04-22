using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.AdminNotes.Command.CreateAdminNote;

internal sealed class CreateAdminNoteCommandHandler
    : ICommandHandler<CreateAdminNoteCommand, AdminNoteDto>
{
    private readonly IAdminNoteService _adminNoteService;

    public CreateAdminNoteCommandHandler(IAdminNoteService adminNoteService)
    {
        _adminNoteService = adminNoteService;
    }

    public async Task<Result<AdminNoteDto>> Handle(
        CreateAdminNoteCommand request,
        CancellationToken cancellationToken)
    {
        var created = await _adminNoteService.CreateAsync(
            request.Title.Trim(),
            request.Text.Trim(),
            request.ImageUrl.Trim(),
            cancellationToken);

        return Result.Success(created);
    }
}
