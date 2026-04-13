using FluentValidation;

namespace LibroSphere.Application.Books.Query.GetAllBooks
{
    public sealed class GetAllBooksQueryValidator : AbstractValidator<GetAllBooksQuery>
    {
        public GetAllBooksQueryValidator()
        {
            RuleFor(x => x.SearchTerm)
                .MaximumLength(200)
                .When(x => !string.IsNullOrWhiteSpace(x.SearchTerm));

            RuleFor(x => x.AuthorId)
                .NotEmpty()
                .When(x => x.AuthorId.HasValue);

            RuleFor(x => x.GenreId)
                .NotEmpty()
                .When(x => x.GenreId.HasValue);

            RuleFor(x => x.MinPrice)
                .GreaterThanOrEqualTo(0)
                .When(x => x.MinPrice.HasValue);

            RuleFor(x => x.MaxPrice)
                .GreaterThanOrEqualTo(0)
                .When(x => x.MaxPrice.HasValue);

            RuleFor(x => x)
                .Must(x => !x.MinPrice.HasValue || !x.MaxPrice.HasValue || x.MinPrice <= x.MaxPrice)
                .WithMessage("MinPrice must be less than or equal to MaxPrice.");

            RuleFor(x => x.Page)
                .GreaterThanOrEqualTo(1);

            RuleFor(x => x.PageSize)
                .InclusiveBetween(1, 100);
        }
    }
}
