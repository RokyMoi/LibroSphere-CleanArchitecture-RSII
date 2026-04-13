using LibroSphere.Application.Genres.Command.CreateGenre;
using LibroSphere.Application.Genres.Command.DeleteGenre;
using LibroSphere.Application.Genres.Command.UpdateGenre;
using LibroSphere.Application.Genres.Query.GetAllGenres;
using LibroSphere.Application.Genres.Query.GetGenreById;
using LibroSphere.Application.Abstractions.Identity;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Genres
{
    [ApiController]
    [Route("api/[controller]")]
    public class GenreController : ControllerBase
    {
        private readonly ISender _sender;

        public GenreController(ISender sender)
        {
            _sender = sender;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] string? searchTerm,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            CancellationToken cancellationToken = default)
        {
            var result = await _sender.Send(new GetAllGenresQuery(searchTerm, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetGenreByIdQuery(id), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [HttpPost]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> Create([FromBody] GenreRequest request, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new CreateGenreCommand(request.Name), cancellationToken);
            return result.IsSuccess
                ? CreatedAtAction(nameof(GetById), new { id = result.Value }, result.Value)
                : BadRequest(result.Error);
        }

        [HttpPut("{id:guid}")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> Update(Guid id, [FromBody] GenreRequest request, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new UpdateGenreCommand(id, request.Name), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }

        [HttpDelete("{id:guid}")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new DeleteGenreCommand(id), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }
    }
}
