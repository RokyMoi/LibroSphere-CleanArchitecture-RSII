using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Domain.Entities.Users;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Infrastructure.Authentication
{
    internal sealed class JwtTokenService : IJwtService
    {
        private readonly JwtOptions _settings;

        public JwtTokenService(IOptions<JwtOptions> settings)
            => _settings = settings.Value;

        public string GenerateAccessToken(User domainUser)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.SecretKey));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
            new Claim(JwtRegisteredClaimNames.Sub, domainUser.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, domainUser.UserEmail.Value),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim("firstName", domainUser.FirstName.Value),
            new Claim("lastName", domainUser.LastName.Value),
        };

            var token = new JwtSecurityToken(
                issuer: _settings.Issuer,
                audience: _settings.Audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(_settings.ExpiryMinutes),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public string GenerateRefreshToken()
            => Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));

        public Guid? GetUserIdFromToken(string token)
        {
            var handler = new JwtSecurityTokenHandler();
            var parameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(_settings.SecretKey)),
                ValidateIssuer = true,
                ValidIssuer = _settings.Issuer,
                ValidateAudience = true,
                ValidAudience = _settings.Audience,
                ValidateLifetime = false //for refresh we dont validate expiry
            };
            try
            {
                var principal = handler.ValidateToken(token, parameters, out _);
                var sub = principal.FindFirstValue(JwtRegisteredClaimNames.Sub);
                return Guid.TryParse(sub, out var id) ? id : null;
            }
            catch { return null; }
        }
    }
}
