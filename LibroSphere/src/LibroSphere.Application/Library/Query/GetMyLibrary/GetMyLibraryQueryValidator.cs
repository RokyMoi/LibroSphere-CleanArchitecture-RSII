using FluentValidation;

namespace LibroSphere.Application.Library.Query.GetMyLibrary
{
    public sealed class GetMyLibraryQueryValidator : AbstractValidator<GetMyLibraryQuery>
    {
        public GetMyLibraryQueryValidator()
        {
            RuleFor(x => x.Email).NotEmpty().EmailAddress();
            RuleFor(x => x.SearchTerm)
                .MaximumLength(200)
                .When(x => !string.IsNullOrWhiteSpace(x.SearchTerm));
            RuleFor(x => x.Page).GreaterThanOrEqualTo(1);
            RuleFor(x => x.PageSize).InclusiveBetween(1, 100);
        }
    }
}
