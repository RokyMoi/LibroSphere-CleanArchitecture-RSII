using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Application.Users.Query.GetUserById;

namespace LibroSphere.Application.Users.Query.GetAllUsers;

public sealed record GetAllUsersQuery(
    string? SearchTerm = null,
    bool? IsActive = null,
    int Page = 1,
    int PageSize = 20) : IQuery<PagedResponse<UserResponse>>;
