using FluentValidation;

namespace LibroSphere.Application.Authors.Command.UpdateAuthor
{
    public sealed class UpdateAuthorCommandValidator : AbstractValidator<UpdateAuthorCommand>
    {
        public UpdateAuthorCommandValidator()
        {
            RuleFor(c => c.AuthorId).NotEmpty();
            RuleFor(c => c.Name.Value).NotEmpty().MaximumLength(100);
            RuleFor(c => c.Biography.Value).NotEmpty().MaximumLength(4000);
        }
    }
}
