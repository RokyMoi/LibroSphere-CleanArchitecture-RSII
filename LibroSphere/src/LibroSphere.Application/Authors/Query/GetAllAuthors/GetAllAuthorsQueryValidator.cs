using FluentValidation;

namespace LibroSphere.Application.Authors.Query.GetAllAuthors
{
    public sealed class GetAllAuthorsQueryValidator : AbstractValidator<GetAllAuthorsQuery>
    {
        public GetAllAuthorsQueryValidator()
        {
            RuleFor(x => x.SearchTerm)
                .MaximumLength(200)
                .When(x => !string.IsNullOrWhiteSpace(x.SearchTerm));

            RuleFor(x => x.Page)
                .GreaterThanOrEqualTo(1);

            RuleFor(x => x.PageSize)
                .InclusiveBetween(1, 100);
        }
    }
}
