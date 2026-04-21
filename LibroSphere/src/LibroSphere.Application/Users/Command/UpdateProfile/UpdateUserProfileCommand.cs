using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Users;
using MediatR;

namespace LibroSphere.Application.Users.Command.UpdateProfile
{
    public sealed record UpdateUserProfileCommand(
        Guid UserId,
        string FirstName,
        string LastName) : IRequest<Result>;

    internal sealed class UpdateUserProfileCommandHandler : IRequestHandler<UpdateUserProfileCommand, Result>
    {
        private readonly IUserRepository _userRepository;
        private readonly IUnitOfWork _unitOfWork;

        public UpdateUserProfileCommandHandler(
            IUserRepository userRepository,
            IUnitOfWork unitOfWork)
        {
            _userRepository = userRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(UpdateUserProfileCommand request, CancellationToken cancellationToken)
        {
            var user = await _userRepository.GetAsyncById(request.UserId, cancellationToken);
            if (user is null)
            {
                return Result.Failure(new Error("User.NotFound", "User not found."));
            }

            user.UpdateProfile(new FirstName(request.FirstName), new LastName(request.LastName));
            
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            
            return Result.Success();
        }
    }
}
