using LibroSphere.Domain.Entities.Users;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Identity
{
    public interface IJwtService
    {
        string GenerateAccessToken(User domainUser);
        string GenerateRefreshToken();
        Guid? GetUserIdFromToken(string token);
    }
}
