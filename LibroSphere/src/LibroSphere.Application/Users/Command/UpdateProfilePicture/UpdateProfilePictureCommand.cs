using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Domain.Entities.Users.Errors;

namespace LibroSphere.Application.Users.Command.UpdateProfilePicture;

public sealed record UpdateProfilePictureCommand(Guid UserId, string? ImageUrl) : ICommand;

internal sealed class UpdateProfilePictureCommandHandler : ICommandHandler<UpdateProfilePictureCommand>
{
    private readonly IUserRepository _userRepository;
    private readonly IUnitOfWork _unitOfWork;

    public UpdateProfilePictureCommandHandler(IUserRepository userRepository, IUnitOfWork unitOfWork)
    {
        _userRepository = userRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result> Handle(UpdateProfilePictureCommand request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetAsyncById(request.UserId, cancellationToken);
        if (user is null)
        {
            return Result.Failure(UserErrors.NotFound(request.UserId));
        }

        user.UpdateProfilePicture(request.ImageUrl);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success();
    }
}
