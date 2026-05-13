using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Library.Query.GetBookReadLink
{
    public sealed record GetBookReadLinkQuery(Guid UserId, Guid BookId) : IQuery<string>;
}
