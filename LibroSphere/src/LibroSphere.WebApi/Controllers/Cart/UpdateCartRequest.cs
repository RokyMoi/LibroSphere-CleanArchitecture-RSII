namespace LibroSphere.WebApi.Controllers.Cart
{
    public sealed class UpdateCartRequest
    {
        public Guid Id { get; set; }
        public List<UpdateCartItemRequest> Items { get; set; } = new();
    }

    public sealed class UpdateCartItemRequest
    {
        public Guid BookId { get; set; }
    }
}
