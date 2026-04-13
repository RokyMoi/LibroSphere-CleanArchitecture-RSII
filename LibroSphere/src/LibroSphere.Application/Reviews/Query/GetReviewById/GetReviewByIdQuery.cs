using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Reviews.Query.GetReviewById
{
    public sealed record GetReviewByIdQuery(Guid ReviewId) : IQuery<ReviewResponse>;
}
