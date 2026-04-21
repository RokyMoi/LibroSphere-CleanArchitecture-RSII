using FluentValidation;

namespace LibroSphere.Application.News.Command.CreateNews;

public sealed class CreateNewsCommandValidator : AbstractValidator<CreateNewsCommand>
{
    public CreateNewsCommandValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty()
            .Length(5, 120);

        RuleFor(x => x.Text)
            .NotEmpty()
            .Length(10, 3000);

        RuleFor(x => x.ImageUrl)
            .NotEmpty()
            .Must(url => Uri.TryCreate(url, UriKind.Absolute, out _))
            .WithMessage("Image URL must be a valid absolute URL (e.g. https://example.com/image.jpg).");
    }
}
