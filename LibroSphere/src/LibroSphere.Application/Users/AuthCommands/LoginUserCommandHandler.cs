using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Users.AuthCommands
{
    internal sealed class LoginUserCommandHandler : ICommandHandler<LoginUserCommand, AuthResult>
    {
        private readonly IAuthService _authService;

        public LoginUserCommandHandler(IAuthService authService)
        {
            _authService = authService;
        }

        public async Task<Result<AuthResult>> Handle(LoginUserCommand request, CancellationToken cancellationToken)
        {
            var result = await _authService.LoginAsync(request, cancellationToken);

            return result.Success
                ? Result.Success(result)
                : Result.Failure<AuthResult>(new Error("Auth.LoginFailed", result.Error ?? "Login failed."));
        }
    }
}
