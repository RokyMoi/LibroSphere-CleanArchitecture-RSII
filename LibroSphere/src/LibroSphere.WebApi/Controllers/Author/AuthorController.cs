using LibroSphere.Application.Authors.Command.CreateNewAuthor;
using LibroSphere.Application.Authors.Command.DeleteAuthor;
using LibroSphere.Application.Authors.Command.UpdateAuthor;
using LibroSphere.Application.Authors.Query.GetAllAuthors;
using LibroSphere.Application.Authors.Query.GetAuthorById;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Domain.Entities.Authors;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Author
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthorController : ControllerBase
    {
        private readonly ISender _sender;

        public AuthorController(ISender sender)
        {
            _sender = sender;
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetAuthorById(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetAuthorByIdQuery(id), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [HttpGet]
        public async Task<IActionResult> GetAllAuthors(
            [FromQuery] string? searchTerm,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            CancellationToken cancellationToken = default)
        {
            var result = await _sender.Send(new GetAllAuthorsQuery(searchTerm, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpPost]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> MakeANewAuthor(AddNewAuthorRequest request, CancellationToken cancellationToken)
        {
            var command = new MakeANewAuthorCommand(
                new Name(request.Name),
                new Biography(request.Biography));

            var result = await _sender.Send(command, cancellationToken);

            return result.IsSuccess
                ? CreatedAtAction(nameof(GetAuthorById), new { id = result.Value }, result.Value)
                : BadRequest(result.Error);
        }

        [HttpPut("{id:guid}")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> UpdateAuthor(Guid id, UpdateAuthorRequest request, CancellationToken cancellationToken)
        {
            var command = new UpdateAuthorCommand(id, new Name(request.Name), new Biography(request.Biography));
            var result = await _sender.Send(command, cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }

        [HttpDelete("{id:guid}")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> DeleteAuthor(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new DeleteAuthorCommand(id), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }
    }
}
