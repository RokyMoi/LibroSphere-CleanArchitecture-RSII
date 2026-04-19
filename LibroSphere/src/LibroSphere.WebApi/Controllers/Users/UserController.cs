using LibroSphere.Application.Users.Query.GetAllUsers;
using LibroSphere.Application.Users.Query.GetUserById;
using LibroSphere.Application.Users.Command.DeleteUser;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Domain.Abstraction;
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
        private readonly ISender sender;

        public UserController(ISender sender)
        {
            this.sender = sender;
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetCurrentUser(CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await sender.Send(new GetUserByIdQuery(userId), cancellationToken);

            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetUserById(Guid id, CancellationToken cancellationToken)
        {
            if (!User.IsAdmin() && id != User.GetRequiredUserId())
            {
                return Forbid();
            }

            var result = await sender.Send(new GetUserByIdQuery(id), cancellationToken);

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
            var result = await sender.Send(new GetAllUsersQuery(searchTerm, isActive, page, pageSize), cancellationToken);

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

            var result = await sender.Send(new DeleteUserCommand(id), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }
    }
}
