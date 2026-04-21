using LibroSphere.Application.Abstractions.Identity;
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
    private readonly IAuthService _authService;

    public AuthController(ISender sender, IAuthService authService)
    {
        _sender = sender;
        _authService = authService;
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
            return Unauthorized(new { Error = "Pogresili ste sifru ili email." });

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

    [Authorize(Roles = ApplicationRoles.Admin)]
    [HttpPost("create-admin")]
    public async Task<IActionResult> CreateAdmin(
        [FromBody] CreateAdminRequest request,
        CancellationToken ct)
    {
        var result = await _authService.CreateAdminAsync(
            request.FirstName,
            request.LastName,
            request.Email,
            request.Password,
            ct);

        if (result.IsFailure)
            return BadRequest(new { Error = result.Error.Message });

        return Ok(new { Message = "Admin nalog je uspjesno kreiran." });
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword(
        [FromBody] ForgotPasswordRequest request,
        CancellationToken ct)
    {
        var result = await _authService.RequestPasswordResetAsync(request.Email, ct);

        if (result.IsFailure)
            return BadRequest(new { Error = result.Error.Message });

        // Always return 200 to avoid revealing whether email exists.
        return Ok(new { Message = "Ako email postoji, kod za reset je poslat." });
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword(
        [FromBody] ResetPasswordRequest request,
        CancellationToken ct)
    {
        var result = await _authService.ResetPasswordWithCodeAsync(
            request.Email,
            request.Code,
            request.NewPassword,
            ct);

        if (result.IsFailure)
            return BadRequest(new { Error = result.Error.Message });

        return Ok(new { Message = "Lozinka je uspjesno promijenjena." });
    }
}

public sealed record CreateAdminRequest(string FirstName, string LastName, string Email, string Password);
public sealed record ForgotPasswordRequest(string Email);
public sealed record ResetPasswordRequest(string Email, string Code, string NewPassword);
