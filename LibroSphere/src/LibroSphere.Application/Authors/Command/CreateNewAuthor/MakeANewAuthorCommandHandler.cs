using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Authors;

namespace LibroSphere.Application.Authors.Command.CreateNewAuthor
{
    internal sealed class MakeANewAuthorCommandHandler : ICommandHandler<MakeANewAuthorCommand, Guid>
    {
        private readonly IAuthorRepository _authorRepository;
        private readonly IUnitOfWork _unitOfWork;

        public MakeANewAuthorCommandHandler(IAuthorRepository authorRepository, IUnitOfWork unitOfWork)
        {
            _authorRepository = authorRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result<Guid>> Handle(MakeANewAuthorCommand request, CancellationToken cancellationToken)
        {
            var author = Author.Create(request.name, request.Biography);
            _authorRepository.Add(author);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            return Result.Success(author.Id);
        }
    }
}
