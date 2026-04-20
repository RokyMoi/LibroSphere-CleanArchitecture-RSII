namespace LibroSphere.Application.Wishlists
{
    public sealed record WishlistItemResponse(
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
        IReadOnlyList<string> GenreNames);

    public sealed record WishlistResponse(Guid WishlistId, Guid UserId, List<WishlistItemResponse> Items);
}
