using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Domain.Abstraction;
using MediatR;

namespace LibroSphere.Application.Users.Command.ResetPassword
{
    public sealed record AdminResetPasswordCommand(
        Guid TargetUserId,
        string NewPassword) : IRequest<Result>;

    internal sealed class AdminResetPasswordCommandHandler : IRequestHandler<AdminResetPasswordCommand, Result>
    {
        private readonly IAuthService _authService;

        public AdminResetPasswordCommandHandler(IAuthService authService)
        {
            _authService = authService;
        }

        public async Task<Result> Handle(AdminResetPasswordCommand request, CancellationToken cancellationToken)
        {
            return await _authService.AdminResetPasswordAsync(request.TargetUserId, request.NewPassword, cancellationToken);
        }
    }
}
