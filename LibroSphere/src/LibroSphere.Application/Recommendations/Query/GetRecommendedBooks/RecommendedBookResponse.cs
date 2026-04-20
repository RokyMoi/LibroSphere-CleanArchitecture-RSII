namespace LibroSphere.Application.Recommendations.Query.GetRecommendedBooks
{
    public sealed record RecommendedBookResponse(
        Guid BookId,
        string Title,
        string Description,
        decimal Amount,
        string Currency,
        string? PdfLink,
        string? ImageLink,
        Guid AuthorId,
        string AuthorName);
}
