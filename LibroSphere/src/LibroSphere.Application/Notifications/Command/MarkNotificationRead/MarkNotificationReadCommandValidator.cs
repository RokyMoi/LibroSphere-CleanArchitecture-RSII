using FluentValidation;

namespace LibroSphere.Application.Notifications.Command.MarkNotificationRead;

public sealed class MarkNotificationReadCommandValidator : AbstractValidator<MarkNotificationReadCommand>
{
    public MarkNotificationReadCommandValidator()
    {
        RuleFor(x => x.UserId)
            .NotEmpty();

        RuleFor(x => x.NotificationId)
            .NotEmpty();
    }
}
