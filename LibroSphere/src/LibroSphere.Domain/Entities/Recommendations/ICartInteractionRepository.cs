namespace LibroSphere.Domain.Entities.Recommendations
{
    public interface ICartInteractionRepository
    {
        /// <summary>
        /// Upserts a durable "added to cart" signal for each book, refreshing the timestamp
        /// for books the user already has a signal for and inserting the rest. No-op when the
        /// collection is empty.
        /// </summary>
        Task RecordAddedToCartAsync(
            Guid userId,
            IReadOnlyCollection<Guid> bookIds,
            CancellationToken cancellationToken = default);
    }
}
