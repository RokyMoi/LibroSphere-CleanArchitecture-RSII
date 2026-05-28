using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Domain.Entities.Reviews;

namespace LibroSphere.Application.Reviews.Query.GetReviewsByBook
{
    internal sealed class GetReviewsByBookQueryHandler : IQueryHandler<GetReviewsByBookQuery, PagedResponse<ReviewResponse>>
    {
        private readonly IReviewRepository _reviewRepository;

        public GetReviewsByBookQueryHandler(IReviewRepository reviewRepository)
        {
            _reviewRepository = reviewRepository;
        }

        public async Task<Result<PagedResponse<ReviewResponse>>> Handle(GetReviewsByBookQuery request, CancellationToken cancellationToken)
        {
            var page = Math.Max(1, request.Page);
            var pageSize = Math.Clamp(request.PageSize, 1, 100);

            var (reviews, totalCount) = await _reviewRepository.GetPagedByBookIdAsync(
                request.BookId,
                request.MinRating,
                request.MaxRating,
                page,
                pageSize,
                cancellationToken);
            var response = reviews
                .Select(review => new ReviewResponse(
                    review.Id,
                    review.UserId,
                    review.BookId,
                    review.Rating,
                    review.Comment,
                    review.CreatedAt,
                    review.User != null ? $"{review.User.FirstName.Value} {review.User.LastName.Value}" : null,
                    review.User?.ProfilePictureUrl))
                .ToList();

            return Result.Success(new PagedResponse<ReviewResponse>(response, page, pageSize, totalCount));
        }
    }
}
