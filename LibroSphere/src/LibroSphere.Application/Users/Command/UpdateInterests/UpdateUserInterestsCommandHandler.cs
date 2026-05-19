using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Application.Users.Command.UpdateInterests
{
    public sealed record UpdateUserInterestsCommand(Guid UserId, List<Guid> AuthorIds) : ICommand;

    internal sealed class UpdateUserInterestsCommandHandler : ICommandHandler<UpdateUserInterestsCommand>
    {
        private readonly IUserRepository _userRepository;
        private readonly IUnitOfWork _unitOfWork;

        public UpdateUserInterestsCommandHandler(IUserRepository userRepository, IUnitOfWork unitOfWork)
        {
            _userRepository = userRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(UpdateUserInterestsCommand request, CancellationToken cancellationToken)
        {
            var user = await _userRepository.GetByIdWithFavoriteAuthorsAsync(request.UserId, cancellationToken);
            if (user is null)
            {
                return Result.Failure(new Error("User.NotFound", "User not found."));
            }

            user.SetFavoriteAuthors(request.AuthorIds);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            return Result.Success();
        }
    }
}
