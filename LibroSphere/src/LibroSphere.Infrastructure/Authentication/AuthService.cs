using System.Security.Cryptography;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Events.User;
using LibroSphere.Application.Users.AuthCommands;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Abstractions.Clock;
using LibroSphere.Domain.Entities.Users;
using MassTransit;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using StackExchange.Redis;

namespace LibroSphere.Infrastructure.Authentication
{
    internal sealed class AuthService : IAuthService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IJwtService _jwtService;
        private readonly IUserRepository _userRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IDateTimeProvider _dateTime;
        private readonly JwtOptions _jwtSettings;
        private readonly IPublishEndpoint _publishEndpoint;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IConnectionMultiplexer _redis;

        private static readonly TimeSpan PasswordResetCodeTtl = TimeSpan.FromMinutes(15);

        public AuthService(
            UserManager<ApplicationUser> userManager,
            IJwtService jwtService,
            IUserRepository userRepository,
            IUnitOfWork unitOfWork,
            IDateTimeProvider dateTime,
            IOptions<JwtOptions> jwtSettings,
            IPublishEndpoint publishEndpoint,
            RoleManager<IdentityRole> roleManager,
            IConnectionMultiplexer redis)
        {
            _userManager = userManager;
            _jwtService = jwtService;
            _userRepository = userRepository;
            _unitOfWork = unitOfWork;
            _dateTime = dateTime;
            _jwtSettings = jwtSettings.Value;
            _publishEndpoint = publishEndpoint;
            _roleManager = roleManager;
            _redis = redis;
        }

        public async Task<AuthResult> RegisterAsync(RegisterUserCommand command, CancellationToken ct = default)
        {
            var existing = await _userManager.FindByEmailAsync(command.Email);
            if (existing is not null)
            {
                return new AuthResult("", "", false, "Email is already in use.");
            }

            var domainUser = User.Create(
                new FirstName(command.FirstName),
                new LastName(command.LastName),
                new Email(command.Email),
                _dateTime);

            var appUser = new ApplicationUser
            {
                UserName = command.Email,
                Email = command.Email,
                DomainUserId = domainUser.Id,
                DomainUser = domainUser,
                DateRegistered = _dateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(appUser, command.Password);
            if (!result.Succeeded)
            {
                return new AuthResult("", "", false, result.Errors.First().Description);
            }

            await EnsureRolesExistAsync();

            var roles = new[] { ApplicationRoles.User };
            var roleResult = await _userManager.AddToRolesAsync(appUser, roles);
            if (!roleResult.Succeeded)
            {
                return new AuthResult("", "", false, roleResult.Errors.First().Description);
            }

            var accessToken = _jwtService.GenerateAccessToken(domainUser, appUser.Id, roles);
            var refreshToken = _jwtService.GenerateRefreshToken();

            var refreshTokenExpiry = _dateTime.UtcNow.AddDays(_jwtSettings.RefreshExpiryDays);
            var persistResult = await PersistRefreshTokenAsync(appUser, refreshToken, refreshTokenExpiry);
            if (!persistResult.Succeeded)
            {
                return new AuthResult("", "", false, persistResult.Errors.First().Description);
            }

            await _publishEndpoint.Publish(
                new UserRegisteredIntegrationEvent(
                    domainUser.Id,
                    command.FirstName,
                    command.LastName,
                    command.Email),
                CancellationToken.None);

            return new AuthResult(accessToken, refreshToken, true);
        }

        public async Task<AuthResult> LoginAsync(LoginUserCommand command, CancellationToken ct = default)
        {
            const string invalidCredentialsMessage = "Invalid email or password.";

            var appUser = await _userManager.FindByEmailAsync(command.Email);
            if (appUser is null)
            {
                return new AuthResult("", "", false, invalidCredentialsMessage);
            }

            var passwordValid = await _userManager.CheckPasswordAsync(appUser, command.Password);
            if (!passwordValid)
            {
                return new AuthResult("", "", false, invalidCredentialsMessage);
            }

            var domainUser = await _userRepository.GetAsyncById(appUser.DomainUserId, ct);
            if (domainUser is null || !domainUser.IsActive)
            {
                return new AuthResult("", "", false, invalidCredentialsMessage);
            }

            domainUser.Login(_dateTime);
            await _unitOfWork.SaveChangesAsync(ct);

            var roles = await _userManager.GetRolesAsync(appUser);
            var accessToken = _jwtService.GenerateAccessToken(domainUser, appUser.Id, roles);
            var refreshToken = _jwtService.GenerateRefreshToken();

            var refreshTokenExpiry = _dateTime.UtcNow.AddDays(_jwtSettings.RefreshExpiryDays);
            var persistResult = await PersistRefreshTokenAsync(appUser, refreshToken, refreshTokenExpiry);
            if (!persistResult.Succeeded)
            {
                return new AuthResult("", "", false, persistResult.Errors.First().Description);
            }

            return new AuthResult(accessToken, refreshToken, true);
        }

        public async Task<AuthResult> RefreshTokenAsync(string refreshToken, CancellationToken ct = default)
        {
            var appUser = await _userManager.Users.FirstOrDefaultAsync(u => u.RefreshToken == refreshToken, ct);
            if (appUser is null)
            {
                return new AuthResult("", "", false, "Invalid refresh token.");
            }

            if (appUser.RefreshTokenExpiry < _dateTime.UtcNow)
            {
                return new AuthResult("", "", false, "Refresh token has expired.");
            }

            var domainUser = await _userRepository.GetAsyncById(appUser.DomainUserId, ct);
            if (domainUser is null)
            {
                return new AuthResult("", "", false, "User not found.");
            }

            var roles = await _userManager.GetRolesAsync(appUser);
            var newAccessToken = _jwtService.GenerateAccessToken(domainUser, appUser.Id, roles);
            var newRefreshToken = _jwtService.GenerateRefreshToken();

            var refreshTokenExpiry = _dateTime.UtcNow.AddDays(_jwtSettings.RefreshExpiryDays);
            var persistResult = await PersistRefreshTokenAsync(appUser, newRefreshToken, refreshTokenExpiry);
            if (!persistResult.Succeeded)
            {
                return new AuthResult("", "", false, persistResult.Errors.First().Description);
            }

            return new AuthResult(newAccessToken, newRefreshToken, true);
        }

        public async Task<AuthResult> LogoutAsync(string userId, CancellationToken ct = default)
        {
            var appUser = await _userManager.FindByIdAsync(userId);
            if (appUser is null && Guid.TryParse(userId, out var domainUserId))
            {
                appUser = await _userManager.Users.FirstOrDefaultAsync(x => x.DomainUserId == domainUserId, ct);
            }

            if (appUser is null)
            {
                return new AuthResult("", "", false, "User not found.");
            }

            var persistResult = await PersistRefreshTokenAsync(appUser, null, null);
            if (!persistResult.Succeeded)
            {
                return new AuthResult("", "", false, persistResult.Errors.First().Description);
            }

            return new AuthResult("", "", true, "Logged out successfully.");
        }

        private Task<IdentityResult> PersistRefreshTokenAsync(
            ApplicationUser appUser,
            string? refreshToken,
            DateTime? refreshTokenExpiry)
        {
            appUser.RefreshToken = refreshToken;
            appUser.RefreshTokenExpiry = refreshTokenExpiry;
            return _userManager.UpdateAsync(appUser);
        }

        public async Task<Result> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword, CancellationToken ct = default)
        {
            var appUser = await _userManager.Users.FirstOrDefaultAsync(u => u.DomainUserId == userId, ct);
            if (appUser is null)
            {
                return Result.Failure(new Error("User.NotFound", "User not found."));
            }

            var changeResult = await _userManager.ChangePasswordAsync(appUser, currentPassword, newPassword);
            if (!changeResult.Succeeded)
            {
                return Result.Failure(new Error("User.Password.ChangeFailed", changeResult.Errors.First().Description));
            }

            return Result.Success();
        }

        public async Task<Result> AdminResetPasswordAsync(Guid targetUserId, string newPassword, CancellationToken ct = default)
        {
            var identityUser = await _userManager.Users.FirstOrDefaultAsync(u => u.DomainUserId == targetUserId, ct);
            if (identityUser is null)
            {
                return Result.Failure(new Error("User.NotFound", "Target user was not found."));
            }

            var token = await _userManager.GeneratePasswordResetTokenAsync(identityUser);
            var result = await _userManager.ResetPasswordAsync(identityUser, token, newPassword);

            if (!result.Succeeded)
            {
                return Result.Failure(new Error("User.Password.ResetFailed", result.Errors.First().Description));
            }

            return Result.Success();
        }

        private async Task EnsureRolesExistAsync()
        {
            if (!await _roleManager.RoleExistsAsync(ApplicationRoles.User))
            {
                await _roleManager.CreateAsync(new IdentityRole(ApplicationRoles.User));
            }

            if (!await _roleManager.RoleExistsAsync(ApplicationRoles.Admin))
            {
                await _roleManager.CreateAsync(new IdentityRole(ApplicationRoles.Admin));
            }
        }

        public async Task<Result> CreateAdminAsync(
            string firstName,
            string lastName,
            string email,
            string password,
            CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(firstName) || string.IsNullOrWhiteSpace(lastName) ||
                string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
            {
                return Result.Failure(new Error("Admin.InvalidInput", "All fields are required."));
            }

            var existing = await _userManager.FindByEmailAsync(email);
            if (existing is not null)
            {
                return Result.Failure(new Error("Admin.EmailInUse", "Email is already in use."));
            }

            var domainUser = User.Create(
                new FirstName(firstName),
                new LastName(lastName),
                new Email(email),
                _dateTime);

            var appUser = new ApplicationUser
            {
                UserName = email,
                Email = email,
                DomainUserId = domainUser.Id,
                DomainUser = domainUser,
                DateRegistered = _dateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(appUser, password);
            if (!result.Succeeded)
            {
                return Result.Failure(new Error("Admin.CreateFailed", result.Errors.First().Description));
            }

            await EnsureRolesExistAsync();

            var roleResult = await _userManager.AddToRolesAsync(
                appUser,
                new[] { ApplicationRoles.User, ApplicationRoles.Admin });
            if (!roleResult.Succeeded)
            {
                return Result.Failure(new Error("Admin.RoleAssignFailed", roleResult.Errors.First().Description));
            }

            await _publishEndpoint.Publish(
                new UserRegisteredIntegrationEvent(
                    domainUser.Id,
                    firstName,
                    lastName,
                    email),
                CancellationToken.None);

            return Result.Success();
        }

        public async Task<Result> RequestPasswordResetAsync(string email, CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                return Result.Failure(new Error("PasswordReset.EmailRequired", "Email is required."));
            }

            var appUser = await _userManager.FindByEmailAsync(email);
            if (appUser is null)
            {
                // Do not reveal whether the email exists for security reasons.
                return Result.Success();
            }

            var code = GenerateResetCode();
            var db = _redis.GetDatabase();
            var key = BuildPasswordResetKey(email);
            await db.StringSetAsync(key, code, PasswordResetCodeTtl);

            await _publishEndpoint.Publish(
                new PasswordResetRequestedIntegrationEvent(
                    email,
                    code,
                    (int)PasswordResetCodeTtl.TotalMinutes),
                CancellationToken.None);

            return Result.Success();
        }

        public async Task<Result> ResetPasswordWithCodeAsync(
            string email,
            string code,
            string newPassword,
            CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(email) ||
                string.IsNullOrWhiteSpace(code) ||
                string.IsNullOrWhiteSpace(newPassword))
            {
                return Result.Failure(new Error("PasswordReset.InvalidInput", "All fields are required."));
            }

            var db = _redis.GetDatabase();
            var key = BuildPasswordResetKey(email);
            var storedCode = await db.StringGetAsync(key);
            if (!storedCode.HasValue || storedCode.ToString() != code.Trim())
            {
                return Result.Failure(new Error("PasswordReset.InvalidCode", "Code is invalid or has expired."));
            }

            var appUser = await _userManager.FindByEmailAsync(email);
            if (appUser is null)
            {
                return Result.Failure(new Error("PasswordReset.InvalidCode", "Code is invalid or has expired."));
            }

            var token = await _userManager.GeneratePasswordResetTokenAsync(appUser);
            var resetResult = await _userManager.ResetPasswordAsync(appUser, token, newPassword);
            if (!resetResult.Succeeded)
            {
                return Result.Failure(new Error("PasswordReset.Failed", resetResult.Errors.First().Description));
            }

            await db.KeyDeleteAsync(key);
            return Result.Success();
        }

        private static string BuildPasswordResetKey(string email) =>
            $"password-reset:{email.Trim().ToLowerInvariant()}";

        private static string GenerateResetCode()
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            Span<char> code = stackalloc char[8];
            for (var i = 0; i < code.Length; i++)
                code[i] = chars[RandomNumberGenerator.GetInt32(chars.Length)];
            return new string(code);
        }
    }
}
