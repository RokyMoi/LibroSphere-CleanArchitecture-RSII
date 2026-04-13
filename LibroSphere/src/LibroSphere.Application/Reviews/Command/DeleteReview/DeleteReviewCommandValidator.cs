using FluentValidation;

namespace LibroSphere.Application.Reviews.Command.DeleteReview
{
    public sealed class DeleteReviewCommandValidator : AbstractValidator<DeleteReviewCommand>
    {
        public DeleteReviewCommandValidator()
        {
            RuleFor(x => x.ReviewId).NotEmpty();
            RuleFor(x => x.UserId).NotEmpty();
        }
    }
}
