using FluentValidation;

namespace LibroSphere.Application.News.Query.GetLatestNews;

public sealed class GetLatestNewsQueryValidator : AbstractValidator<GetLatestNewsQuery>
{
    public GetLatestNewsQueryValidator()
    {
        RuleFor(x => x.Take)
            .InclusiveBetween(1, 100);
    }
}
