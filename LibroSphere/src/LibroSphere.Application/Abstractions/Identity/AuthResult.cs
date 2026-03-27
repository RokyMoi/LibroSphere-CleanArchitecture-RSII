using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Identity { 
public record AuthResult(
    string AccessToken,
    string RefreshToken,
    bool Success,
    string? Error = null
);
}
