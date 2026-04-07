using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Users.AuthCommands
{
    internal sealed class LogoutUserCommandHandler : ICommandHandler<LogoutUserCommand, AuthResult>
    {
        private readonly IAuthService _authService;

        public LogoutUserCommandHandler(IAuthService authService)
        {
            _authService = authService;
        }

        public async Task<Result<AuthResult>> Handle(LogoutUserCommand request, CancellationToken cancellationToken)
        {
            var result = await _authService.LogoutAsync(request.UserId, cancellationToken);

            return result.Success
                ? Result.Success(result)
                : Result.Failure<AuthResult>(new Error("Auth.LogoutFailed", result.Error ?? "Logout failed."));
        }
    }
}
