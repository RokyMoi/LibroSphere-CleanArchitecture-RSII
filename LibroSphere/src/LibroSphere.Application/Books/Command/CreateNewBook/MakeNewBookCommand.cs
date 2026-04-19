using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace LibroSphere.Application.Books.Command.CreateNewBook
{
    public record MakeNewBookCommand(Title title,
            Description description,
            Money price,
            BookLinks bookLinks,
            Guid authorId,
            List<Guid> GenreIds) :ICommand<Guid>;
}
