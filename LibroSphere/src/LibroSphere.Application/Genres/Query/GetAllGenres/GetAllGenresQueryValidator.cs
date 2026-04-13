using FluentValidation;

namespace LibroSphere.Application.Genres.Query.GetAllGenres
{
    public sealed class GetAllGenresQueryValidator : AbstractValidator<GetAllGenresQuery>
    {
        public GetAllGenresQueryValidator()
        {
            RuleFor(x => x.SearchTerm)
                .MaximumLength(100)
                .When(x => !string.IsNullOrWhiteSpace(x.SearchTerm));

            RuleFor(x => x.Page)
                .GreaterThanOrEqualTo(1);

            RuleFor(x => x.PageSize)
                .InclusiveBetween(1, 100);
        }
    }
}
