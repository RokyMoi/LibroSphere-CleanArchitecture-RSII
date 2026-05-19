using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Application.Users.Query.GetUserInterests
{
    public sealed record GetUserInterestsQuery(Guid UserId) : IQuery<List<Guid>>;

    internal sealed class GetUserInterestsQueryHandler : IQueryHandler<GetUserInterestsQuery, List<Guid>>
    {
        private readonly IUserRepository _userRepository;

        public GetUserInterestsQueryHandler(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<Result<List<Guid>>> Handle(GetUserInterestsQuery request, CancellationToken cancellationToken)
        {
            var user = await _userRepository.GetByIdWithFavoriteAuthorsAsync(request.UserId, cancellationToken);
            if (user is null)
            {
                return Result.Failure<List<Guid>>(new Error("User.NotFound", "User not found."));
            }

            var authorIds = user.FavoriteAuthors.Select(fa => fa.AuthorId).ToList();
            return Result.Success(authorIds);
        }
    }
}
