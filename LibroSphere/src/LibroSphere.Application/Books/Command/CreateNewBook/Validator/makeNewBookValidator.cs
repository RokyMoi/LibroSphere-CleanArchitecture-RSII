using FluentValidation;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Books.Command.CreateNewBook.Validator
{


    public class MakeNewBookCommandValidator : AbstractValidator<MakeNewBookCommand>
    {
        public MakeNewBookCommandValidator()
        {
            RuleFor(c => c.title.Value)
         .NotEmpty().WithMessage("Title cannot be empty.")
          .MaximumLength(200).WithMessage("Title cannot exceed 200 characters.");

            RuleFor(c => c.description.Value)
                .NotEmpty().WithMessage("Description cannot be empty.")
                .MaximumLength(2000).WithMessage("Description cannot exceed 2000 characters.");

            RuleFor(c => c.price.amount)
                .GreaterThan(0).WithMessage("Price must be greater than 0.");

            RuleFor(c => c.price.Currency.Code)
                .NotEmpty().WithMessage("Currency cannot be empty.")
                .Length(3).WithMessage("Currency must be in ISO format (e.g. USD, EUR, BAM).");

            RuleFor(c => c.authorId)
                .NotEmpty().WithMessage("AuthorId cannot be empty.");

            RuleFor(c => c.bookLinks.PdfLink)
                .NotEmpty().WithMessage("Pdf link cannot be empty.");

            RuleFor(c => c.bookLinks.imageLink)
                .NotEmpty().WithMessage("Image link cannot be empty.");

            RuleFor(c => c.GenreIds)
                .NotEmpty().WithMessage("At least one genre is required.");
        }
    }
}
