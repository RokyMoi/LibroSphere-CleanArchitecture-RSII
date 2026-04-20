using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Domain.Entities.Users.Errors;

namespace LibroSphere.Application.Users.Query.GetUserById;

internal sealed class GetUserByIdQueryHandler : IQueryHandler<GetUserByIdQuery, UserResponse>
{
    private readonly IUserRepository _userRepository;

    public GetUserByIdQueryHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<Result<UserResponse>> Handle(GetUserByIdQuery request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetReadOnlyByIdAsync(request.UserId, cancellationToken);
        if (user is null)
        {
            return Result.Failure<UserResponse>(UserErrors.NotFound(request.UserId));
        }

        return Result.Success(new UserResponse(
            user.Id,
            user.FirstName.Value,
            user.LastName.Value,
            user.UserEmail.Value,
            user.DateRegistered,
            user.LastLogin,
            user.IsActive));
    }
}
