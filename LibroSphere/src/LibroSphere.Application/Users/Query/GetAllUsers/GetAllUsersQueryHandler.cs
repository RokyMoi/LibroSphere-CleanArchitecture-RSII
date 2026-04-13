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
        var users = await _userRepository.GetAllAsync(cancellationToken);

        var response = users
            .Where(user =>
                string.IsNullOrWhiteSpace(request.SearchTerm) ||
                user.FirstName.Value.Contains(request.SearchTerm, StringComparison.OrdinalIgnoreCase) ||
                user.LastName.Value.Contains(request.SearchTerm, StringComparison.OrdinalIgnoreCase) ||
                user.UserEmail.Value.Contains(request.SearchTerm, StringComparison.OrdinalIgnoreCase))
            .Where(user => !request.IsActive.HasValue || user.IsActive == request.IsActive.Value)
            .Select(user => new UserResponse(
                user.Id,
                user.FirstName.Value,
                user.LastName.Value,
                user.UserEmail.Value,
                user.DateRegistered,
                user.LastLogin,
                user.IsActive))
            .ToList();

        return Result.Success(PagedResponse<UserResponse>.Create(response, request.Page, request.PageSize));
    }
}
