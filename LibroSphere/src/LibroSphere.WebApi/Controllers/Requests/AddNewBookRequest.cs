namespace LibroSphere.WebApi.Controllers.Requests
{
    public class AddNewBookRequest
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public decimal PriceAmount { get; set; } 
        public string CurrencyCode { get; set; }
        public string PdfLink { get; set; }
        public string? ImageLink { get; set; }
        public Guid AuthorId { get; set; }
    }
}
