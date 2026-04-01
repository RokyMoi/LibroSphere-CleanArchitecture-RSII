
using LibroSphere.Application.Users.AuthCommands;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Identity
{
    public interface IAuthService
    {
        Task<AuthResult> RegisterAsync(RegisterUserCommand command, CancellationToken ct = default);
        Task<AuthResult> LoginAsync(LoginUserCommand command, CancellationToken ct = default);
        Task<AuthResult> RefreshTokenAsync(string refreshToken, CancellationToken ct = default);
     Task<AuthResult> LogoutAsync(string userId, CancellationToken ct = default);
    }


   
}
