namespace LibroSphere.Domain.Entities.Recommendations
{
    /// <summary>
    /// Durable recommender signal: records that a user placed a book in their cart.
    /// The live cart lives in Redis, so this persistent row is what the recommender
    /// reads instead of the (unused) SQL ShoppingCarts/ShoppingCartItems tables.
    /// One row per (UserId, BookId); the timestamp is refreshed on every re-add.
    /// </summary>
    public sealed class CartInteraction
    {
        public Guid UserId { get; set; }
        public Guid BookId { get; set; }
        public DateTime LastAddedAt { get; set; }
    }
}
