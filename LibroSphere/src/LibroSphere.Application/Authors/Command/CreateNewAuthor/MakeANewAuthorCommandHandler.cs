using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Authors;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace LibroSphere.Application.Authors.Command.CreateNewAuthor
{
    public class MakeANewAuthorCommandHandler : ICommandHandler<MakeANewAuthorCommand, Guid>
    {
        IAuthorRepository authorRepo;
        IUnitOfWork unitOfWork;
        public MakeANewAuthorCommandHandler(IUnitOfWork _unit, IAuthorRepository autho)
        {
            unitOfWork = _unit;
            authorRepo = autho;
        }

        public async Task<Result<Guid>> Handle(MakeANewAuthorCommand request, CancellationToken cancellationToken)
        {
            var author = Author.Create(request.name, request.Biography);

            authorRepo.Add(author);
             await unitOfWork.SaveChangesAsync();

            return Result.Success(author.Id);
        }
    }
}
