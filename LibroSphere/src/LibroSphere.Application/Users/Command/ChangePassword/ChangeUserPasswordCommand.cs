using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Domain.Abstraction;
using MediatR;

namespace LibroSphere.Application.Users.Command.ChangePassword
{
    public sealed record ChangeUserPasswordCommand(
        Guid UserId,
        string CurrentPassword,
        string NewPassword) : IRequest<Result>;

    internal sealed class ChangeUserPasswordCommandHandler : IRequestHandler<ChangeUserPasswordCommand, Result>
    {
        private readonly IAuthService _authService;

        public ChangeUserPasswordCommandHandler(IAuthService authService)
        {
            _authService = authService;
        }

        public async Task<Result> Handle(ChangeUserPasswordCommand request, CancellationToken cancellationToken)
        {
            return await _authService.ChangePasswordAsync(request.UserId, request.CurrentPassword, request.NewPassword, cancellationToken);
        }
    }
}
