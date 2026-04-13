using FluentValidation;

namespace LibroSphere.Application.Reviews.Query.GetReviewsByBook
{
    public sealed class GetReviewsByBookQueryValidator : AbstractValidator<GetReviewsByBookQuery>
    {
        public GetReviewsByBookQueryValidator()
        {
            RuleFor(x => x.BookId).NotEmpty();

            RuleFor(x => x.MinRating)
                .InclusiveBetween(1, 5)
                .When(x => x.MinRating.HasValue);

            RuleFor(x => x.MaxRating)
                .InclusiveBetween(1, 5)
                .When(x => x.MaxRating.HasValue);

            RuleFor(x => x)
                .Must(x => !x.MinRating.HasValue || !x.MaxRating.HasValue || x.MinRating <= x.MaxRating)
                .WithMessage("MinRating must be less than or equal to MaxRating.");

            RuleFor(x => x.Page).GreaterThanOrEqualTo(1);
            RuleFor(x => x.PageSize).InclusiveBetween(1, 100);
        }
    }
}
