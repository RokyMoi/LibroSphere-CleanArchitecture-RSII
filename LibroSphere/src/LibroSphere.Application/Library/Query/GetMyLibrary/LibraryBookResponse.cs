namespace LibroSphere.Application.Library.Query.GetMyLibrary
{
    public sealed record LibraryBookResponse(Guid BookId, string Title, string? ImageLink, DateTime PurchasedAt);
}
