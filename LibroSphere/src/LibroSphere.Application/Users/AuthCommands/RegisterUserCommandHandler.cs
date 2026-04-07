using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Users.AuthCommands
{
    internal sealed class RegisterUserCommandHandler : ICommandHandler<RegisterUserCommand, AuthResult>
    {
        private readonly IAuthService _authService;

        public RegisterUserCommandHandler(IAuthService authService)
        {
            _authService = authService;
        }

        public async Task<Result<AuthResult>> Handle(RegisterUserCommand request, CancellationToken cancellationToken)
        {
            var result = await _authService.RegisterAsync(request, cancellationToken);

            return result.Success
                ? Result.Success(result)
                : Result.Failure<AuthResult>(new Error("Auth.RegisterFailed", result.Error ?? "Registration failed."));
        }
    }
}
