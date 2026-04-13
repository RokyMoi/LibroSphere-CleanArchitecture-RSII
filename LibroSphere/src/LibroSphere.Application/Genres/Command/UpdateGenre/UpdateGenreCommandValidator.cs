using FluentValidation;

namespace LibroSphere.Application.Genres.Command.UpdateGenre
{
    public sealed class UpdateGenreCommandValidator : AbstractValidator<UpdateGenreCommand>
    {
        public UpdateGenreCommandValidator()
        {
            RuleFor(x => x.GenreId).NotEmpty();
            RuleFor(x => x.Name)
                .NotEmpty()
                .MaximumLength(100);
        }
    }
}
