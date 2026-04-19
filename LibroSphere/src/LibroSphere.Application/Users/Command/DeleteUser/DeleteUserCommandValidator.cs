using FluentValidation;

namespace LibroSphere.Application.Users.Command.DeleteUser
{
    public sealed class DeleteUserCommandValidator : AbstractValidator<DeleteUserCommand>
    {
        public DeleteUserCommandValidator()
        {
            RuleFor(c => c.UserId).NotEmpty();
        }
    }
}
