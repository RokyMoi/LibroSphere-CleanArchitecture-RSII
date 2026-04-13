using FluentValidation;

namespace LibroSphere.Application.Genres.Query.GetGenreById
{
    public sealed class GetGenreByIdQueryValidator : AbstractValidator<GetGenreByIdQuery>
    {
        public GetGenreByIdQueryValidator()
        {
            RuleFor(x => x.GenreId).NotEmpty();
        }
    }
}
