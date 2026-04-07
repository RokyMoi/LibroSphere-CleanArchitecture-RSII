using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Users.AuthCommands
{
    internal sealed class RefreshTokenCommandHandler : ICommandHandler<RefreshTokenCommand, AuthResult>
    {
        private readonly IAuthService _authService;

        public RefreshTokenCommandHandler(IAuthService authService)
        {
            _authService = authService;
        }

        public async Task<Result<AuthResult>> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
        {
            var result = await _authService.RefreshTokenAsync(request.RefreshToken, cancellationToken);

            return result.Success
                ? Result.Success(result)
                : Result.Failure<AuthResult>(new Error("Auth.RefreshFailed", result.Error ?? "Refresh token failed."));
        }
    }
}
