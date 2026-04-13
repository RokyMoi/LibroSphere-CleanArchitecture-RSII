using FluentValidation;

namespace LibroSphere.Application.Reviews.Command.CreateReview
{
    public sealed class CreateReviewCommandValidator : AbstractValidator<CreateReviewCommand>
    {
        public CreateReviewCommandValidator()
        {
            RuleFor(x => x.UserId).NotEmpty();
            RuleFor(x => x.BookId).NotEmpty();
            RuleFor(x => x.Rating).InclusiveBetween(1, 5);
            RuleFor(x => x.Comment).NotEmpty().MaximumLength(2000);
        }
    }
}
