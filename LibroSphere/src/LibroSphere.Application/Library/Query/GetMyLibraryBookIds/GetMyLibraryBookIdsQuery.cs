using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Library.Query.GetMyLibraryBookIds
{
    public sealed record GetMyLibraryBookIdsQuery(Guid UserId) : IQuery<IReadOnlyList<Guid>>;
}
