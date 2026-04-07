namespace LibroSphere.WebApi.Controllers.Cart
{
    public sealed class UpdateCartRequest
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? ClientSecret { get; set; }
        public string? PaymentIntentId { get; set; }
        public List<UpdateCartItemRequest> Items { get; set; } = new();
    }

    public sealed class UpdateCartItemRequest
    {
        public Guid BookId { get; set; }
        public UpdateCartPriceRequest Price { get; set; } = new();
    }

    public sealed class UpdateCartPriceRequest
    {
        public decimal Amount { get; set; }
        public string CurrencyCode { get; set; } = "USD";
    }
}
