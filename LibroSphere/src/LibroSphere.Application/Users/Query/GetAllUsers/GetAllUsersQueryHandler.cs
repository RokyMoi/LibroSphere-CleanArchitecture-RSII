using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Application.Users.Query.GetUserById;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Application.Users.Query.GetAllUsers;

internal sealed class GetAllUsersQueryHandler : IQueryHandler<GetAllUsersQuery, PagedResponse<UserResponse>>
{
    private readonly IUserRepository _userRepository;

    public GetAllUsersQueryHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<Result<PagedResponse<UserResponse>>> Handle(GetAllUsersQuery request, CancellationToken cancellationToken)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var (users, totalCount) = await _userRepository.GetPagedAsync(
            request.SearchTerm, request.IsActive, page, pageSize, cancellationToken);

        var items = users.Select(user => new UserResponse(
                user.Id,
                user.FirstName.Value,
                user.LastName.Value,
                user.UserEmail.Value,
                user.DateRegistered,
                user.LastLogin,
                user.IsActive))
            .ToList();

        return Result.Success(PagedResponse<UserResponse>.Create(items, page, pageSize, totalCount));
    }
}
