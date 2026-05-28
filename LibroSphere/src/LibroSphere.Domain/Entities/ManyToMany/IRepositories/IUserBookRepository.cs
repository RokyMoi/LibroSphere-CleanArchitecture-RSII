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
        Task AddAsync(UserBook userBook);
        Task RemoveAsync(UserBook userBook);
        Task SaveChangesAsync();
    }
}
