using FluentValidation;

namespace LibroSphere.Application.Authors.Command.CreateNewAuthor.Validator
{
    public sealed class MakeANewAuthorCommandValidator : AbstractValidator<MakeANewAuthorCommand>
    {
        public MakeANewAuthorCommandValidator()
        {
            RuleFor(c => c.name.Value)
                .NotEmpty()
                .MaximumLength(100);

            RuleFor(c => c.Biography.Value)
                .NotEmpty()
                .MaximumLength(4000);
        }
    }
}
