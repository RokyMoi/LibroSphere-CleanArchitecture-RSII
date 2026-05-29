namespace LibroSphere.Domain.Entities.ManyToMany.IRepositories
{
    public interface IUserBookRepository
    {
        Task<List<UserBook>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
        Task<(List<UserBook> Items, int TotalCount)> GetPagedByUserIdAsync(
            Guid userId,
            string? searchTerm,
            int page,
            int pageSize,
            CancellationToken cancellationToken = default);
        Task<bool> HasAccessAsync(Guid userId, Guid bookId, CancellationToken cancellationToken = default);
        /// <summary>Returns the set of bookIds the user already owns (one DB round-trip).</summary>
        Task<HashSet<Guid>> GetOwnedBookIdsAsync(Guid userId, IEnumerable<Guid> bookIds, CancellationToken cancellationToken = default);
        Task AddAsync(UserBook userBook);
        /// <summary>
        /// Idempotently grants a book to a user in its own transaction. Returns false when the
        /// user already owned the book (including when a concurrent insert won the race), true
        /// when this call inserted the row. Never throws on a duplicate-key conflict.
        /// </summary>
        Task<bool> AddIfNotExistsAsync(UserBook userBook, CancellationToken cancellationToken = default);
        Task RemoveAsync(UserBook userBook);
        void RemoveRange(IEnumerable<UserBook> userBooks);
        Task SaveChangesAsync();
    }
}
