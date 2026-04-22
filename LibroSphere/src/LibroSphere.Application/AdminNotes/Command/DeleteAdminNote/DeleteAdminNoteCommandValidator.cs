using FluentValidation;

namespace LibroSphere.Application.AdminNotes.Command.DeleteAdminNote;

public sealed class DeleteAdminNoteCommandValidator : AbstractValidator<DeleteAdminNoteCommand>
{
    public DeleteAdminNoteCommandValidator()
    {
        RuleFor(x => x.Id)
            .NotEmpty();
    }
}
