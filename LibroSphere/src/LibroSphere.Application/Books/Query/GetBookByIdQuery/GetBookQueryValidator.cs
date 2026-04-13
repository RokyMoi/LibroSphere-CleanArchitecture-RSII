using FluentValidation;

namespace LibroSphere.Application.Books.Query.GetBookByIdQuery
{
    public sealed class GetBookQueryValidator : AbstractValidator<GetBookQuery>
    {
        public GetBookQueryValidator()
        {
            RuleFor(x => x.bookId)
                .NotEmpty();
        }
    }
}
