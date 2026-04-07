using LibroSphere.Application.Authors.Command.CreateNewAuthor;
using LibroSphere.Application.Authors.Command.DeleteAuthor;
using LibroSphere.Application.Authors.Command.UpdateAuthor;
using LibroSphere.Application.Authors.Query.GetAllAuthors;
using LibroSphere.Application.Authors.Query.GetAuthorById;
using LibroSphere.Domain.Entities.Authors;
using MediatR;
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
        public async Task<IActionResult> GetAllAuthors(CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetAllAuthorsQuery(), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpPost]
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
        public async Task<IActionResult> UpdateAuthor(Guid id, UpdateAuthorRequest request, CancellationToken cancellationToken)
        {
            var command = new UpdateAuthorCommand(id, new Name(request.Name), new Biography(request.Biography));
            var result = await _sender.Send(command, cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> DeleteAuthor(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new DeleteAuthorCommand(id), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }
    }
}
