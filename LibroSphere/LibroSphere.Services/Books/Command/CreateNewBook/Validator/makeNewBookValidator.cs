using FluentValidation;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Books.Command.CreateNewBook.Validator
{
    public class MakeaBookCommandValidator : AbstractValidator<MakeNewBookCommand>
    {
        public MakeaBookCommandValidator()
        {
            //Ovo je samo primjer Validacije
           /// RuleFor(c => c.bookLinks.PdfLink).MinimumLength(300);
        }
    }
}
