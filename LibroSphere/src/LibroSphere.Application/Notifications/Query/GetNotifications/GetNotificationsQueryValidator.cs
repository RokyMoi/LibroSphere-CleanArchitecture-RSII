using FluentValidation;

namespace LibroSphere.Application.Notifications.Query.GetNotifications;

public sealed class GetNotificationsQueryValidator : AbstractValidator<GetNotificationsQuery>
{
    public GetNotificationsQueryValidator()
    {
        RuleFor(x => x.UserId)
            .NotEmpty();

        RuleFor(x => x.Take)
            .InclusiveBetween(1, 100);
    }
}
