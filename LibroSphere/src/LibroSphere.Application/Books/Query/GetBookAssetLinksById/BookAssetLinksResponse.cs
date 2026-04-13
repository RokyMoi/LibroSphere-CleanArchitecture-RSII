namespace LibroSphere.Application.Books.Query.GetBookAssetLinksById;

public sealed class BookAssetLinksResponse
{
    public Guid BookId { get; init; }
    public string PdfLink { get; init; } = string.Empty;
    public string? ImageLink { get; init; }
}
