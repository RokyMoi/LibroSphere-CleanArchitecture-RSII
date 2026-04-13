using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Library.Query.GetBookReadLink
{
    public sealed record GetBookReadLinkQuery(string Email, Guid BookId) : IQuery<string>;
}
