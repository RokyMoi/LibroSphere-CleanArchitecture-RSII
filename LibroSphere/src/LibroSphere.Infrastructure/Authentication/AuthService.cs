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
        private readonly AccessControlOptions _accessControlOptions;
        private readonly ApplicationDbContext _dbContext;

        public AuthService(
            UserManager<ApplicationUser> userManager,
            IJwtService jwtService,
            IUserRepository userRepository,
            IUnitOfWork unitOfWork,
            IDateTimeProvider dateTime,
            IOptions<JwtOptions> jwtSettings,
            IPublishEndpoint publishEndpoint,
            RoleManager<IdentityRole> roleManager,
            IOptions<AccessControlOptions> accessControlOptions,
            ApplicationDbContext dbContext)
        {
            _userManager = userManager;
            _jwtService = jwtService;
            _userRepository = userRepository;
            _unitOfWork = unitOfWork;
            _dateTime = dateTime;
            _jwtSettings = jwtSettings.Value;
            _publishEndpoint = publishEndpoint;
            _roleManager = roleManager;
            _accessControlOptions = accessControlOptions.Value;
            _dbContext = dbContext;
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

            var roles = await DetermineRolesForUserAsync(appUser);
            var roleResult = await _userManager.AddToRolesAsync(appUser, roles);
            if (!roleResult.Succeeded)
            {
                return new AuthResult("", "", false, roleResult.Errors.First().Description);
            }

            var accessToken = _jwtService.GenerateAccessToken(domainUser, appUser.Id, roles);
            var refreshToken = _jwtService.GenerateRefreshToken();

            var refreshTokenExpiry = _dateTime.UtcNow.AddDays(_jwtSettings.RefreshExpiryDays);
            await PersistRefreshTokenAsync(appUser.Id, refreshToken, refreshTokenExpiry, ct);

            await _publishEndpoint.Publish(
                new UserRegisteredIntegrationEvent(
                    domainUser.Id,
                    command.FirstName,
                    command.LastName,
                    command.Email,
                    command.Password),
                ct);

            return new AuthResult(accessToken, refreshToken, true);
        }

        public async Task<AuthResult> LoginAsync(LoginUserCommand command, CancellationToken ct = default)
        {
            var appUser = await _userManager.FindByEmailAsync(command.Email);
            if (appUser is null)
            {
                return new AuthResult("", "", false, "Invalid credentials.");
            }

            var passwordValid = await _userManager.CheckPasswordAsync(appUser, command.Password);
            if (!passwordValid)
            {
                return new AuthResult("", "", false, "Invalid credentials.");
            }

            var domainUser = await _userRepository.GetAsyncById(appUser.DomainUserId, ct);
            if (domainUser is null || !domainUser.IsActive)
            {
                return new AuthResult("", "", false, "Account is inactive.");
            }

            domainUser.Login(_dateTime);
            await _unitOfWork.SaveChangesAsync(ct);

            var roles = await _userManager.GetRolesAsync(appUser);
            var accessToken = _jwtService.GenerateAccessToken(domainUser, appUser.Id, roles);
            var refreshToken = _jwtService.GenerateRefreshToken();

            var refreshTokenExpiry = _dateTime.UtcNow.AddDays(_jwtSettings.RefreshExpiryDays);
            await PersistRefreshTokenAsync(appUser.Id, refreshToken, refreshTokenExpiry, ct);

            return new AuthResult(accessToken, refreshToken, true);
        }

        public async Task<AuthResult> RefreshTokenAsync(string refreshToken, CancellationToken ct = default)
        {
            var appUser = _userManager.Users.FirstOrDefault(u => u.RefreshToken == refreshToken);
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
            await PersistRefreshTokenAsync(appUser.Id, newRefreshToken, refreshTokenExpiry, ct);

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

            await PersistRefreshTokenAsync(appUser.Id, null, null, ct);

            return new AuthResult("", "", true, "Logged out successfully.");
        }

        private Task PersistRefreshTokenAsync(
            string appUserId,
            string? refreshToken,
            DateTime? refreshTokenExpiry,
            CancellationToken cancellationToken)
        {
            return _dbContext.Users
                .Where(user => user.Id == appUserId)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(user => user.RefreshToken, refreshToken)
                    .SetProperty(user => user.RefreshTokenExpiry, refreshTokenExpiry),
                    cancellationToken);
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

        private async Task<IReadOnlyCollection<string>> DetermineRolesForUserAsync(ApplicationUser appUser)
        {
            var roles = new List<string> { ApplicationRoles.User };
            var isConfiguredAdmin = _accessControlOptions.AdminEmails.Any(email =>
                email.Equals(appUser.Email, StringComparison.OrdinalIgnoreCase));

            if (isConfiguredAdmin)
            {
                roles.Add(ApplicationRoles.Admin);
                return roles;
            }

            var admins = await _userManager.GetUsersInRoleAsync(ApplicationRoles.Admin);
            if (admins.Count == 0)
            {
                roles.Add(ApplicationRoles.Admin);
            }

            return roles;
        }
    }
}
