namespace LibroSphere.Domain.Entities.Reviews
{
    public sealed record BookReviewStats(int Count, double Average);

    public interface IReviewRepository
    {
        Task<Review?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        Task<Review?> GetReadOnlyByIdAsync(Guid id, CancellationToken cancellationToken = default);
        Task<List<Review>> GetByBookIdAsync(Guid bookId, int? minRating = null, int? maxRating = null, CancellationToken cancellationToken = default);
        Task<List<Review>> GetByUserIdAsync(Guid userId, int? minRating = null, int? maxRating = null, CancellationToken cancellationToken = default);
        Task<Review?> GetByUserAndBookAsync(Guid userId, Guid bookId, CancellationToken cancellationToken = default);
        Task<IReadOnlyDictionary<Guid, BookReviewStats>> GetStatsForBooksAsync(IReadOnlyCollection<Guid> bookIds, CancellationToken cancellationToken = default);
        void Add(Review review);
        void Delete(Review review);
    }
}
