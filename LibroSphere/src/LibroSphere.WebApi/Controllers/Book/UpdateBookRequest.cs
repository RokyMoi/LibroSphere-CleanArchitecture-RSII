namespace LibroSphere.WebApi.Controllers.Book
{
    public sealed class UpdateBookRequest
    {
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal PriceAmount { get; set; }
        public string CurrencyCode { get; set; } = string.Empty;
        public string PdfLink { get; set; } = string.Empty;
        public string? ImageLink { get; set; }
        public Guid AuthorId { get; set; }
        public List<Guid>? GenreIds { get; set; }
    }
}
