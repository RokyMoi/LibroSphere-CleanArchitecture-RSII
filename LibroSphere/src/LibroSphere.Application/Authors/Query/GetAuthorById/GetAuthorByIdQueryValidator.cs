using FluentValidation;

namespace LibroSphere.Application.Authors.Query.GetAuthorById
{
    public sealed class GetAuthorByIdQueryValidator : AbstractValidator<GetAuthorByIdQuery>
    {
        public GetAuthorByIdQueryValidator()
        {
            RuleFor(x => x.autorId)
                .NotEmpty();
        }
    }
}
