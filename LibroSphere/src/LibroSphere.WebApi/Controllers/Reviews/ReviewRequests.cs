namespace LibroSphere.WebApi.Controllers.Reviews
{
    public sealed class CreateReviewRequest
    {
        public Guid BookId { get; set; }
        public int Rating { get; set; }
        public string Comment { get; set; } = string.Empty;
    }

    public sealed class UpdateReviewRequest
    {
        public int Rating { get; set; }
        public string Comment { get; set; } = string.Empty;
    }
}
