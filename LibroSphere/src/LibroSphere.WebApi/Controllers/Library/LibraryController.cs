using LibroSphere.Application.Library.Query.GetBookReadLink;
using LibroSphere.Application.Library.Query.GetMyLibrary;
using LibroSphere.Application.Library.Query.GetMyLibraryBookIds;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Library
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class LibraryController : ControllerBase
    {
        private readonly ISender _sender;

        public LibraryController(ISender sender)
        {
            _sender = sender;
        }

        [HttpGet]
        public async Task<IActionResult> GetMyLibrary(
            [FromQuery] string? searchTerm,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 12,
            CancellationToken cancellationToken = default)
        {
            pageSize = Math.Clamp(pageSize, 1, 100);
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new GetMyLibraryQuery(userId, searchTerm, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpGet("owned-ids")]
        public async Task<IActionResult> GetOwnedBookIds(CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new GetMyLibraryBookIdsQuery(userId), cancellationToken);
            return result.IsSuccess
                ? Ok(new { bookIds = result.Value })
                : BadRequest(result.Error);
        }

        [HttpGet("{bookId:guid}/read")]
        public async Task<IActionResult> GetPdfLink(Guid bookId, CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new GetBookReadLinkQuery(userId, bookId), cancellationToken);
            return result.IsSuccess ? Ok(new { pdfUrl = result.Value }) : Forbid();
        }
    }
}
