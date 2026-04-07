namespace LibroSphere.Domain.Entities.Reviews
{
    public interface IReviewRepository
    {
        Task<Review?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        Task<List<Review>> GetByBookIdAsync(Guid bookId, CancellationToken cancellationToken = default);
        Task<List<Review>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
        Task<Review?> GetByUserAndBookAsync(Guid userId, Guid bookId, CancellationToken cancellationToken = default);
        void Add(Review review);
        void Delete(Review review);
    }
}
