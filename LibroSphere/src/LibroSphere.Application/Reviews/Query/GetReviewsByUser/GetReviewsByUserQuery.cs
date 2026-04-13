using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;

namespace LibroSphere.Application.Reviews.Query.GetReviewsByUser
{
    public sealed record GetReviewsByUserQuery(
        Guid UserId,
        int? MinRating = null,
        int? MaxRating = null,
        int Page = 1,
        int PageSize = 10) : IQuery<PagedResponse<ReviewResponse>>;
}
