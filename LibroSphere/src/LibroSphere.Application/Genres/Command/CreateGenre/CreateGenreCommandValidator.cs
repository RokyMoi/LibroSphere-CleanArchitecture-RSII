using FluentValidation;

namespace LibroSphere.Application.Genres.Command.CreateGenre
{
    public sealed class CreateGenreCommandValidator : AbstractValidator<CreateGenreCommand>
    {
        public CreateGenreCommandValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty()
                .MaximumLength(100);
        }
    }
}
