namespace LibroSphere.Application.Library.Query.GetMyLibrary
{
    public sealed record LibraryBookResponse(
        Guid BookId,
        string Title,
        string Description,
        decimal Amount,
        string Currency,
        string? PdfLink,
        string? ImageLink,
        double AverageRating,
        int ReviewCount,
        Guid AuthorId,
        string AuthorName,
        IReadOnlyList<Guid> GenreIds,
        IReadOnlyList<string> GenreNames,
        DateTime PurchasedAt);
}
