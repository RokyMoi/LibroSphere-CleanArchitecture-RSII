using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.Reviews.Errors;

namespace LibroSphere.Application.Reviews.Command.DeleteReview
{
    internal sealed class DeleteReviewCommandHandler : ICommandHandler<DeleteReviewCommand>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly IUnitOfWork _unitOfWork;

        public DeleteReviewCommandHandler(IReviewRepository reviewRepository, IUnitOfWork unitOfWork)
        {
            _reviewRepository = reviewRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(DeleteReviewCommand request, CancellationToken cancellationToken)
        {
            var review = await _reviewRepository.GetAsyncById(request.ReviewId, cancellationToken);
            if (review is null || review.UserId != request.UserId)
            {
                return Result.Failure(ReviewErrors.NotFound);
            }

            review.MarkAsDeleted();
            _reviewRepository.Delete(review);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
