using FluentValidation;

namespace LibroSphere.Application.Users.Query.GetUserById;

public sealed class GetUserByIdQueryValidator : AbstractValidator<GetUserByIdQuery>
{
    public GetUserByIdQueryValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
    }
}
