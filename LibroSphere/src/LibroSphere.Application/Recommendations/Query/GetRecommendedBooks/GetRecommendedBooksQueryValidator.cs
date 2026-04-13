using FluentValidation;

namespace LibroSphere.Application.Recommendations.Query.GetRecommendedBooks
{
    public sealed class GetRecommendedBooksQueryValidator : AbstractValidator<GetRecommendedBooksQuery>
    {
        public GetRecommendedBooksQueryValidator()
        {
            RuleFor(x => x.UserId).NotEmpty();
            RuleFor(x => x.Take).InclusiveBetween(1, 20);
        }
    }
}
