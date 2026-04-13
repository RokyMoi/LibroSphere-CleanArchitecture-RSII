using FluentValidation;

namespace LibroSphere.Application.Users.Query.GetAllUsers;

public sealed class GetAllUsersQueryValidator : AbstractValidator<GetAllUsersQuery>
{
    public GetAllUsersQueryValidator()
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
