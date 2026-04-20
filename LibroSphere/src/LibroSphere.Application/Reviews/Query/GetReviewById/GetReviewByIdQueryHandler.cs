using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.Reviews.Errors;

namespace LibroSphere.Application.Reviews.Query.GetReviewById
{
    internal sealed class GetReviewByIdQueryHandler : IQueryHandler<GetReviewByIdQuery, ReviewResponse>
    {
        private readonly IReviewRepository _reviewRepository;

        public GetReviewByIdQueryHandler(IReviewRepository reviewRepository)
        {
            _reviewRepository = reviewRepository;
        }

        public async Task<Result<ReviewResponse>> Handle(GetReviewByIdQuery request, CancellationToken cancellationToken)
        {
            var review = await _reviewRepository.GetReadOnlyByIdAsync(request.ReviewId, cancellationToken);
            if (review is null)
            {
                return Result.Failure<ReviewResponse>(ReviewErrors.NotFound);
            }

            return Result.Success(new ReviewResponse(review.Id, review.UserId, review.BookId, review.Rating, review.Comment, review.CreatedAt));
        }
    }
}
