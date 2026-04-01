using LibroSphere.Application.Abstractions.Identity;

using LibroSphere.Application.Users.AuthCommands;
using LibroSphere.WebApi.Controllers.Auth;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(
        [FromBody] RegisterUserCommand command,
        CancellationToken ct)
    {
        var result = await _authService.RegisterAsync(command, ct);

        if (!result.Success)
            return BadRequest(new { Error = result.Error });

        return Ok(new
        {
            AccessToken = result.AccessToken,
            RefreshToken = result.RefreshToken
        });
    }
    [HttpPost("logout")]
    public async Task<ActionResult> LogoutAsync([FromBody] string userId, CancellationToken ct)
    {
        await _authService.LogoutAsync(userId, ct);
        return Ok(new { Message = "Logged out successfully." });
    }
    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginUserCommand command,
        CancellationToken ct)
    {
        var result = await _authService.LoginAsync(command, ct);

        if (!result.Success)
            return Unauthorized(new { Error = result.Error });

        return Ok(new
        {
            AccessToken = result.AccessToken,
            RefreshToken = result.RefreshToken
        });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh(
        [FromBody] RefreshTokenRequest request,
        CancellationToken ct)
    {
        var result = await _authService.RefreshTokenAsync(request.RefreshToken, ct);

        if (!result.Success)
            return Unauthorized(new { Error = result.Error });

        return Ok(new
        {
            AccessToken = result.AccessToken,
            RefreshToken = result.RefreshToken
        });
    }
}

