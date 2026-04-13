using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Users.Query.GetUserById;

public sealed record GetUserByIdQuery(Guid UserId) : IQuery<UserResponse>;
