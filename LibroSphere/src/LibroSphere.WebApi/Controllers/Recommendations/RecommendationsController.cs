using LibroSphere.Application.Recommendations.Query.GetRecommendedBooks;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Recommendations
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class RecommendationsController : ControllerBase
    {
        private readonly ISender _sender;

        public RecommendationsController(ISender sender)
        {
            _sender = sender;
        }

        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] int take = 5, CancellationToken cancellationToken = default)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new GetRecommendedBooksQuery(userId, take), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }
    }
}
