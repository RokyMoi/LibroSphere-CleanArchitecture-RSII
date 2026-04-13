using FluentValidation;

namespace LibroSphere.Application.Books.Query.GetBookAssetLinksById;

public sealed class GetBookAssetLinksQueryValidator : AbstractValidator<GetBookAssetLinksQuery>
{
    public GetBookAssetLinksQueryValidator()
    {
        RuleFor(x => x.BookId)
            .NotEmpty();
    }
}
