using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;

namespace LibroSphere.Application.Library.Query.GetMyLibraryBookIds
{
    internal sealed class GetMyLibraryBookIdsQueryHandler
        : IQueryHandler<GetMyLibraryBookIdsQuery, IReadOnlyList<Guid>>
    {
        private readonly IUserBookRepository _userBookRepository;

        public GetMyLibraryBookIdsQueryHandler(IUserBookRepository userBookRepository)
        {
            _userBookRepository = userBookRepository;
        }

        public async Task<Result<IReadOnlyList<Guid>>> Handle(
            GetMyLibraryBookIdsQuery request,
            CancellationToken cancellationToken)
        {
            var bookIds = await _userBookRepository.GetAllBookIdsByUserIdAsync(request.UserId, cancellationToken);
            return Result.Success<IReadOnlyList<Guid>>(bookIds);
        }
    }
}
