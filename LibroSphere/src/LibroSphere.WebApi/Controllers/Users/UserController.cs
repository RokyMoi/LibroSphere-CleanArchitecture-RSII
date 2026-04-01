
using LibroSphere.Application.Users;
using LibroSphere.Application.Users.AuthCommands;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Users
{
    [ApiController]
    [Route("api/user")]
    public class UserController : ControllerBase
    {
        private readonly ISender sender;

        public UserController(ISender sender)
        {
            this.sender = sender;
        }
        [AllowAnonymous]
        [HttpPost("register")]
        public async Task<IActionResult> Register(RegisterUserRequest request, CancellationToken cancellationToken)
        {
            var command = new RegisterUserCommand(request.Email,
                request.FirstName,
                request.LastName,
                request.password);

            var result = await sender.Send(command, cancellationToken);
            if (result.IsFailure)
            {
                return BadRequest(result.Error);
            }
            return Ok(result.Value);
        }
    }
}
