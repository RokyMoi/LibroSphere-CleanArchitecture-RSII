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
            var reviews = await _reviewRepository.GetByBookIdAsync(request.BookId, cancellationToken);
            var response = reviews
                .Where(review => !request.MinRating.HasValue || review.Rating >= request.MinRating.Value)
                .Where(review => !request.MaxRating.HasValue || review.Rating <= request.MaxRating.Value)
                .Select(review => new ReviewResponse(review.Id, review.UserId, review.BookId, review.Rating, review.Comment, review.CreatedAt))
                .ToList();

            return Result.Success(PagedResponse<ReviewResponse>.Create(response, request.Page, request.PageSize));
        }
    }
}
