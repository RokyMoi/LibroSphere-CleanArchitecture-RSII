using FluentValidation;

namespace LibroSphere.Application.Books.Command.UpdateBook
{
    public sealed class UpdateBookCommandValidator : AbstractValidator<UpdateBookCommand>
    {
        public UpdateBookCommandValidator()
        {
            RuleFor(c => c.BookId).NotEmpty();
            RuleFor(c => c.Title.Value).NotEmpty().MaximumLength(200);
            RuleFor(c => c.Description.Value).NotEmpty().MaximumLength(2000);
            RuleFor(c => c.Price.amount).GreaterThan(0);
            RuleFor(c => c.Price.Currency.Code).NotEmpty().Length(3);
            RuleFor(c => c.AuthorId).NotEmpty();
            RuleFor(c => c.BookLinks.PdfLink).NotEmpty();
            RuleFor(c => c.BookLinks.imageLink).NotEmpty();
            RuleFor(c => c.GenreIds).NotEmpty();
        }
    }
}
