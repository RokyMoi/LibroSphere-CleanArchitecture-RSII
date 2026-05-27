using FluentValidation;

namespace LibroSphere.Application.Users.Command.ResetPassword
{
    internal sealed class AdminResetPasswordCommandValidator : AbstractValidator<AdminResetPasswordCommand>
    {
        public AdminResetPasswordCommandValidator()
        {
            RuleFor(x => x.TargetUserId).NotEmpty();
            RuleFor(x => x.NewPassword).NotEmpty().MinimumLength(8);
        }
    }
}
