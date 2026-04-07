using FluentValidation;

namespace LibroSphere.Application.Books.Command.DeleteBook
{
    public sealed class DeleteBookCommandValidator : AbstractValidator<DeleteBookCommand>
    {
        public DeleteBookCommandValidator()
        {
            RuleFor(c => c.BookId).NotEmpty();
        }
    }
}
