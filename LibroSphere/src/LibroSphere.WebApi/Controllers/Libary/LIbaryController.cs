using LibroSphere.Application.Library.Query.GetBookReadLink;
using LibroSphere.Application.Library.Query.GetMyLibrary;
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
            var email = User.GetRequiredEmail();
            var result = await _sender.Send(new GetMyLibraryQuery(email, searchTerm, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpGet("{bookId:guid}/read")]
        public async Task<IActionResult> GetPdfLink(Guid bookId, CancellationToken cancellationToken)
        {
            var email = User.GetRequiredEmail();
            var result = await _sender.Send(new GetBookReadLinkQuery(email, bookId), cancellationToken);
            return result.IsSuccess ? Ok(new { pdfUrl = result.Value }) : Forbid();
        }
    }
}
