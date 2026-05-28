using FluentValidation;

namespace LibroSphere.Application.Users.Command.UpdateInterests;

public sealed class UpdateUserInterestsCommandValidator : AbstractValidator<UpdateUserInterestsCommand>
{
    public UpdateUserInterestsCommandValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
        RuleForEach(x => x.AuthorIds).NotEmpty().WithMessage("Each author ID must be a valid non-empty value.");
    }
}
