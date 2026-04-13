using FluentValidation;

namespace LibroSphere.Application.Genres.Command.DeleteGenre
{
    public sealed class DeleteGenreCommandValidator : AbstractValidator<DeleteGenreCommand>
    {
        public DeleteGenreCommandValidator()
        {
            RuleFor(x => x.GenreId).NotEmpty();
        }
    }
}
