using FluentValidation;

namespace LibroSphere.Application.Library.Query.GetBookReadLink
{
    public sealed class GetBookReadLinkQueryValidator : AbstractValidator<GetBookReadLinkQuery>
    {
        public GetBookReadLinkQueryValidator()
        {
            RuleFor(x => x.Email).NotEmpty().EmailAddress();
            RuleFor(x => x.BookId).NotEmpty();
        }
    }
}
