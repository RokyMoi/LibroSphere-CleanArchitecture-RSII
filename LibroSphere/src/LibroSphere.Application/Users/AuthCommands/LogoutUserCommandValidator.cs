using FluentValidation;

namespace LibroSphere.Application.Users.AuthCommands
{
    internal sealed class LogoutUserCommandValidator : AbstractValidator<LogoutUserCommand>
    {
        public LogoutUserCommandValidator()
        {
            RuleFor(x => x.UserId)
                .NotEmpty();
        }
    }
}
