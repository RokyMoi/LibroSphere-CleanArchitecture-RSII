using FluentValidation;

namespace LibroSphere.Application.Reviews.Query.GetReviewById
{
    public sealed class GetReviewByIdQueryValidator : AbstractValidator<GetReviewByIdQuery>
    {
        public GetReviewByIdQueryValidator()
        {
            RuleFor(x => x.ReviewId).NotEmpty();
        }
    }
}
