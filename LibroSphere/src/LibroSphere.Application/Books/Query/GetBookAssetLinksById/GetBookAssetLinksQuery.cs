using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Books.Query.GetBookAssetLinksById;

public sealed record GetBookAssetLinksQuery(Guid BookId) : IQuery<BookAssetLinksResponse>;
