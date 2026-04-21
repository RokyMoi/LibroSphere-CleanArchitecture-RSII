using FluentValidation;

namespace LibroSphere.Application.News.Command.DeleteNews;

public sealed class DeleteNewsCommandValidator : AbstractValidator<DeleteNewsCommand>
{
    public DeleteNewsCommandValidator()
    {
        RuleFor(x => x.Id)
            .NotEmpty();
    }
}
