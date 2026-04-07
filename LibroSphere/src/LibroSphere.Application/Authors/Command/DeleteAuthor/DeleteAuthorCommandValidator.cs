using FluentValidation;

namespace LibroSphere.Application.Authors.Command.DeleteAuthor
{
    public sealed class DeleteAuthorCommandValidator : AbstractValidator<DeleteAuthorCommand>
    {
        public DeleteAuthorCommandValidator()
        {
            RuleFor(c => c.AuthorId).NotEmpty();
        }
    }
}
