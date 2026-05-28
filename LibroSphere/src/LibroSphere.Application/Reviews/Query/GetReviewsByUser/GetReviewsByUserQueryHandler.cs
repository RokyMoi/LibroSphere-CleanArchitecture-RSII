using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Domain.Entities.Reviews;

namespace LibroSphere.Application.Reviews.Query.GetReviewsByUser
{
    internal sealed class GetReviewsByUserQueryHandler : IQueryHandler<GetReviewsByUserQuery, PagedResponse<ReviewResponse>>
    {
        private readonly IReviewRepository _reviewRepository;

        public GetReviewsByUserQueryHandler(IReviewRepository reviewRepository)
        {
            _reviewRepository = reviewRepository;
        }

        public async Task<Result<PagedResponse<ReviewResponse>>> Handle(GetReviewsByUserQuery request, CancellationToken cancellationToken)
        {
            var page = Math.Max(1, request.Page);
            var pageSize = Math.Clamp(request.PageSize, 1, 100);

            var (reviews, totalCount) = await _reviewRepository.GetPagedByUserIdAsync(
                request.UserId,
                request.MinRating,
                request.MaxRating,
                page,
                pageSize,
                cancellationToken);
            var response = reviews
                .Select(review => new ReviewResponse(review.Id, review.UserId, review.BookId, review.Rating, review.Comment, review.CreatedAt))
                .ToList();

            return Result.Success(new PagedResponse<ReviewResponse>(response, page, pageSize, totalCount));
        }
    }
}
