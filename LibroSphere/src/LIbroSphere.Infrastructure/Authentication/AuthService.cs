using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Users;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Abstractions.Clock;
using LibroSphere.Domain.Entities.Users;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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

        public AuthService(UserManager<ApplicationUser> userManager,
            IJwtService jwtService, IUserRepository userRepository,
            IUnitOfWork unitOfWork, IDateTimeProvider dateTime,
            IOptions<JwtOptions> jwtSettings)
        {
            _userManager = userManager;
            _jwtService = jwtService;
            _userRepository = userRepository;
            _unitOfWork = unitOfWork;
            _dateTime = dateTime;
            _jwtSettings = jwtSettings.Value;
        }

        public async Task<AuthResult> RegisterAsync(RegisterUserCommand command, CancellationToken ct = default)
        {
            var existing = await _userManager.FindByEmailAsync(command.Email);
            if (existing is not null)
                return new AuthResult("", "", false, "Email is already in use.");

            var domainUser = User.Create(
                new FirstName(command.FirstName), new LastName(command.LastName),
                new Email(command.Email), _dateTime);

            var appUser = new ApplicationUser
            {
                UserName = command.Email,
                Email = command.Email,
                DomainUserId = domainUser.Id,
                DomainUser = domainUser
            };

            var result = await _userManager.CreateAsync(appUser, command.Password);
            if (!result.Succeeded)
                return new AuthResult("", "", false, result.Errors.First().Description);

            var accessToken = _jwtService.GenerateAccessToken(domainUser);
            var refreshToken = _jwtService.GenerateRefreshToken();

            appUser.RefreshToken = refreshToken;
            appUser.RefreshTokenExpiry = _dateTime.UtcNow.AddDays(_jwtSettings.RefreshExpiryDays);
            await _userManager.UpdateAsync(appUser);

            return new AuthResult(accessToken, refreshToken, true);
        }

        public async Task<AuthResult> LoginAsync(LoginUserCommand command, CancellationToken ct = default)
        {
            var appUser = await _userManager.FindByEmailAsync(command.Email);
            if (appUser is null)
                return new AuthResult("", "", false, "Invalid credentials.");

            var passwordValid = await _userManager.CheckPasswordAsync(appUser, command.Password);
            if (!passwordValid)
                return new AuthResult("", "", false, "Invalid credentials.");

            var domainUser = await _userRepository.GetAsyncById(appUser.DomainUserId, ct);
            if (domainUser is null || !domainUser.IsActive)
                return new AuthResult("", "", false, "Account is inactive.");

            domainUser.Login(_dateTime);
            await _unitOfWork.SaveChangesAsync(ct);

            var accessToken = _jwtService.GenerateAccessToken(domainUser);
            var refreshToken = _jwtService.GenerateRefreshToken();

            appUser.RefreshToken = refreshToken;
            appUser.RefreshTokenExpiry = _dateTime.UtcNow.AddDays(_jwtSettings.RefreshExpiryDays);
            await _userManager.UpdateAsync(appUser);

            return new AuthResult(accessToken, refreshToken, true);
        }

        public async Task<AuthResult> RefreshTokenAsync(string refreshToken, CancellationToken ct = default)
        {
            var appUser = _userManager.Users.FirstOrDefault(u => u.RefreshToken == refreshToken);
            if (appUser is null)
                return new AuthResult("", "", false, "Invalid refresh token.");

            if (appUser.RefreshTokenExpiry < _dateTime.UtcNow)
                return new AuthResult("", "", false, "Refresh token has expired.");

            var domainUser = await _userRepository.GetAsyncById(appUser.DomainUserId, ct);
            if (domainUser is null)
                return new AuthResult("", "", false, "User not found.");

            var newAccessToken = _jwtService.GenerateAccessToken(domainUser);
            var newRefreshToken = _jwtService.GenerateRefreshToken();

            appUser.RefreshToken = newRefreshToken;
            appUser.RefreshTokenExpiry = _dateTime.UtcNow.AddDays(_jwtSettings.RefreshExpiryDays);
            await _userManager.UpdateAsync(appUser);

            return new AuthResult(newAccessToken, newRefreshToken, true);
        }
        public async Task<AuthResult> LogoutAsync(string userId, CancellationToken ct = default)
        {
            var appUser = await _userManager.FindByIdAsync(userId);
            if (appUser is null)
                return new AuthResult("", "", false, "User not found.");

            // Brišemo refresh token
            appUser.RefreshToken = null;
            appUser.RefreshTokenExpiry = null;
            await _userManager.UpdateAsync(appUser);

            return new AuthResult("", "", true, "Logged out successfully.");
        }

    }
}
