using LibroSphere.Application.Users.Query.GetAllUsers;
using LibroSphere.Application.Users.Query.GetUserById;
using LibroSphere.Application.Users.Command.DeleteUser;
using LibroSphere.Application.Users.Command.UpdateProfile;
using LibroSphere.Application.Users.Command.UpdateProfilePicture;
using LibroSphere.Application.Users.Command.ChangePassword;
using LibroSphere.Application.Users.Command.ResetPassword;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Infrastructure;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Users
{
    [ApiController]
    [Route("api/user")]
    [Authorize]
    public class UserController : ControllerBase
    {
        private readonly ISender _sender;
        private readonly IBookAssetStorageService _storageService;
        private const long MaxImageBytes = 10 * 1024 * 1024;
        private static readonly HashSet<string> AllowedImageContentTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/webp"
        };

        public UserController(ISender sender, IBookAssetStorageService storageService)
        {
            _sender = sender;
            _storageService = storageService;
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetCurrentUser(CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new GetUserByIdQuery(userId), cancellationToken);

            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetUserById(Guid id, CancellationToken cancellationToken)
        {
            if (!User.IsAdmin() && id != User.GetRequiredUserId())
            {
                return Forbid();
            }

            var result = await _sender.Send(new GetUserByIdQuery(id), cancellationToken);

            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [Authorize(Roles = ApplicationRoles.Admin)]
        [HttpGet]
        public async Task<IActionResult> GetAllUsers(
            [FromQuery] string? searchTerm,
            [FromQuery] bool? isActive,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            CancellationToken cancellationToken = default)
        {
            var result = await _sender.Send(new GetAllUsersQuery(searchTerm, isActive, page, pageSize), cancellationToken);

            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [Authorize(Roles = ApplicationRoles.Admin)]
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> DeleteUser(Guid id, CancellationToken cancellationToken)
        {
            if (id == User.GetRequiredUserId())
            {
                return BadRequest(new Error("Users.DeleteSelfForbidden", "You cannot delete the currently signed-in admin user."));
            }

            var result = await _sender.Send(new DeleteUserCommand(id), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }

        [HttpPut("me/profile")]
        public async Task<IActionResult> UpdateMyProfile(
            [FromBody] UpdateProfileRequest request,
            CancellationToken cancellationToken)
        {
            var firstName = request.FirstName?.Trim() ?? string.Empty;
            var lastName = request.LastName?.Trim() ?? string.Empty;
            var errors = new Dictionary<string, string[]>();

            if (string.IsNullOrWhiteSpace(firstName) || firstName.Length > 100)
            {
                errors[nameof(request.FirstName)] = new[]
                {
                    "First name is required and must contain between 1 and 100 characters."
                };
            }

            if (string.IsNullOrWhiteSpace(lastName) || lastName.Length > 100)
            {
                errors[nameof(request.LastName)] = new[]
                {
                    "Last name is required and must contain between 1 and 100 characters."
                };
            }

            if (errors.Count > 0)
            {
                return BadRequest(new
                {
                    code = "User.Profile.ValidationFailed",
                    message = "Profile update validation failed.",
                    errors
                });
            }

            var command = new UpdateUserProfileCommand(User.GetRequiredUserId(), firstName, lastName);
            var result = await _sender.Send(command, cancellationToken);

            if (result.IsFailure)
            {
                return BadRequest(result.Error);
            }

            return Ok(new UpdateProfileResponse(firstName, lastName, "Profile updated successfully."));
        }

        [HttpPost("me/profile-picture")]
        public async Task<IActionResult> UploadProfilePicture(IFormFile file, CancellationToken cancellationToken)
        {
            if (file is null || file.Length == 0)
            {
                return BadRequest(new { Error = "No file provided." });
            }

            if (file.Length > MaxImageBytes)
            {
                return BadRequest(new { Error = "Image must be smaller than 10MB." });
            }

            if (!AllowedImageContentTypes.Contains(file.ContentType))
            {
                return BadRequest(new { Error = "Image must be jpeg, jpg, png or webp." });
            }

            var userId = User.GetRequiredUserId();

            await using var stream = file.OpenReadStream();
            var uploadResult = await _storageService.UploadImageAsync(
                stream,
                file.FileName,
                file.ContentType,
                cancellationToken);

            var imageUrl = await _storageService.GetImageUrlAsync(uploadResult.StoredValue, cancellationToken);

            var command = new UpdateProfilePictureCommand(userId, imageUrl);
            var result = await _sender.Send(command, cancellationToken);

            if (result.IsFailure)
            {
                return BadRequest(result.Error);
            }

            return Ok(new { ProfilePictureUrl = imageUrl, Message = "Profile picture updated successfully." });
        }

        [HttpPost("me/change-password")]
        public async Task<IActionResult> ChangeMyPassword(
            [FromBody] ChangePasswordRequest request,
            CancellationToken cancellationToken)
        {
            var errors = new Dictionary<string, string[]>();

            if (string.IsNullOrWhiteSpace(request.CurrentPassword))
            {
                errors[nameof(request.CurrentPassword)] = new[]
                {
                    "Current password is required."
                };
            }

            if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 8)
            {
                errors[nameof(request.NewPassword)] = new[]
                {
                    "New password must be at least 8 characters and include uppercase letter and number."
                };
            }

            if (!string.Equals(request.NewPassword, request.ConfirmNewPassword, StringComparison.Ordinal))
            {
                errors[nameof(request.ConfirmNewPassword)] = new[]
                {
                    "Password confirmation does not match the new password."
                };
            }

            if (errors.Count > 0)
            {
                return BadRequest(new
                {
                    code = "User.Password.ValidationFailed",
                    message = "Password change validation failed.",
                    errors
                });
            }

            var command = new ChangeUserPasswordCommand(User.GetRequiredUserId(), request.CurrentPassword, request.NewPassword);
            var result = await _sender.Send(command, cancellationToken);

            if (result.IsFailure)
            {
                return BadRequest(new
                {
                    code = result.Error.Code,
                    message = result.Error.Message
                });
            }

            return Ok(new { message = "Password updated successfully." });
        }

        [Authorize(Roles = ApplicationRoles.Admin)]
        [HttpPost("{id:guid}/reset-password")]
        public async Task<IActionResult> AdminResetPassword(
            Guid id,
            [FromBody] AdminResetPasswordRequest request,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 8)
            {
                return BadRequest(new
                {
                    code = "User.Password.ValidationFailed",
                    message = "New password must be at least 8 characters and include uppercase letter and number."
                });
            }

            if (!string.Equals(request.NewPassword, request.ConfirmNewPassword, StringComparison.Ordinal))
            {
                return BadRequest(new
                {
                    code = "User.Password.ConfirmationMismatch",
                    message = "Password confirmation does not match the new password."
                });
            }

            var command = new AdminResetPasswordCommand(id, request.NewPassword);
            var result = await _sender.Send(command, cancellationToken);

            if (result.IsFailure)
            {
                return BadRequest(new
                {
                    code = result.Error.Code,
                    message = result.Error.Message
                });
            }

            return Ok(new { message = "Password has been reset successfully." });
        }
    }

    public sealed record UpdateProfileRequest(string FirstName, string LastName);
    public sealed record UpdateProfileResponse(string FirstName, string LastName, string Message);

    public sealed record ChangePasswordRequest(
        string CurrentPassword,
        string NewPassword,
        string ConfirmNewPassword);

    public sealed record AdminResetPasswordRequest(
        string NewPassword,
        string ConfirmNewPassword);
}
