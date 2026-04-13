using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.Reviews.Errors;

namespace LibroSphere.Application.Reviews.Command.UpdateReview
{
    internal sealed class UpdateReviewCommandHandler : ICommandHandler<UpdateReviewCommand>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly IUnitOfWork _unitOfWork;

        public UpdateReviewCommandHandler(IReviewRepository reviewRepository, IUnitOfWork unitOfWork)
        {
            _reviewRepository = reviewRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(UpdateReviewCommand request, CancellationToken cancellationToken)
        {
            var review = await _reviewRepository.GetAsyncById(request.ReviewId, cancellationToken);
            if (review is null || review.UserId != request.UserId)
            {
                return Result.Failure(ReviewErrors.NotFound);
            }

            review.Update(request.Rating, request.Comment);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
