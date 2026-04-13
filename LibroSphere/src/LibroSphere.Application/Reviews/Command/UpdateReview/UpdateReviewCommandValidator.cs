using FluentValidation;

namespace LibroSphere.Application.Reviews.Command.UpdateReview
{
    public sealed class UpdateReviewCommandValidator : AbstractValidator<UpdateReviewCommand>
    {
        public UpdateReviewCommandValidator()
        {
            RuleFor(x => x.ReviewId).NotEmpty();
            RuleFor(x => x.UserId).NotEmpty();
            RuleFor(x => x.Rating).InclusiveBetween(1, 5);
            RuleFor(x => x.Comment).NotEmpty().MaximumLength(2000);
        }
    }
}
