using LibroSphere.Application.Reviews.Command.CreateReview;
using LibroSphere.Application.Reviews.Command.DeleteReview;
using LibroSphere.Application.Reviews.Command.UpdateReview;
using LibroSphere.Application.Reviews.Query.GetReviewById;
using LibroSphere.Application.Reviews.Query.GetReviewsByBook;
using LibroSphere.Application.Reviews.Query.GetReviewsByUser;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Reviews
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReviewsController : ControllerBase
    {
        private readonly ISender _sender;

        public ReviewsController(ISender sender)
        {
            _sender = sender;
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetReviewByIdQuery(id), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [HttpGet("book/{bookId:guid}")]
        public async Task<IActionResult> GetByBook(
            Guid bookId,
            [FromQuery] int? minRating,
            [FromQuery] int? maxRating,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            CancellationToken cancellationToken = default)
        {
            var result = await _sender.Send(new GetReviewsByBookQuery(bookId, minRating, maxRating, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> GetMine(
            [FromQuery] int? minRating,
            [FromQuery] int? maxRating,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            CancellationToken cancellationToken = default)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new GetReviewsByUserQuery(userId, minRating, maxRating, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [Authorize]
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateReviewRequest request, CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(
                new CreateReviewCommand(userId, request.BookId, request.Rating, request.Comment),
                cancellationToken);

            return result.IsSuccess
                ? CreatedAtAction(nameof(GetById), new { id = result.Value }, result.Value)
                : BadRequest(result.Error);
        }

        [Authorize]
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] UpdateReviewRequest request, CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new UpdateReviewCommand(id, userId, request.Rating, request.Comment), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }

        [Authorize]
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new DeleteReviewCommand(id, userId), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }
    }
}
