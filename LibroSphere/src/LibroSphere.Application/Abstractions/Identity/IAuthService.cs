
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
         Task<Result> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword, CancellationToken ct = default);
         Task<Result> AdminResetPasswordAsync(Guid targetUserId, string newPassword, CancellationToken ct = default);
         Task<Result> CreateAdminAsync(string firstName, string lastName, string email, string password, CancellationToken ct = default);
         Task<Result> RequestPasswordResetAsync(string email, CancellationToken ct = default);
         Task<Result> ResetPasswordWithCodeAsync(string email, string code, string newPassword, CancellationToken ct = default);
    }


   
}
