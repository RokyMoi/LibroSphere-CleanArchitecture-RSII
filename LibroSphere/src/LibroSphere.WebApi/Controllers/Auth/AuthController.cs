using LibroSphere.Application.Users.AuthCommands;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Auth;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ISender _sender;

    public AuthController(ISender sender)
    {
        _sender = sender;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(
        [FromBody] RegisterUserCommand command,
        CancellationToken ct)
    {
        var result = await _sender.Send(command, ct);

        if (result.IsFailure)
            return BadRequest(new { Error = result.Error });

        return Ok(new
        {
            AccessToken = result.Value.AccessToken,
            RefreshToken = result.Value.RefreshToken
        });
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<ActionResult> LogoutAsync(CancellationToken ct)
    {
        var result = await _sender.Send(new LogoutUserCommand(User.GetRequiredIdentityUserId()), ct);

        if (result.IsFailure)
            return BadRequest(new { Error = result.Error });

        return Ok(new { Message = result.Value.Error ?? "Logged out successfully." });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginUserCommand command,
        CancellationToken ct)
    {
        var result = await _sender.Send(command, ct);

        if (result.IsFailure)
            return Unauthorized(new { Error = result.Error });

        return Ok(new
        {
            AccessToken = result.Value.AccessToken,
            RefreshToken = result.Value.RefreshToken
        });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh(
        [FromBody] RefreshTokenRequest request,
        CancellationToken ct)
    {
        var result = await _sender.Send(new RefreshTokenCommand(request.RefreshToken), ct);

        if (result.IsFailure)
            return Unauthorized(new { Error = result.Error });

        return Ok(new
        {
            AccessToken = result.Value.AccessToken,
            RefreshToken = result.Value.RefreshToken
        });
    }
}
