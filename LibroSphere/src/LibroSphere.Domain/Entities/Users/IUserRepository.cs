namespace LibroSphere.Domain.Entities.Users
{
    public interface IUserRepository
    {
        Task<User?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        Task<User?> GetReadOnlyByIdAsync(Guid id, CancellationToken cancellationToken = default);
        Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
        Task<User?> GetByIdWithFavoriteAuthorsAsync(Guid id, CancellationToken cancellationToken = default);
        Task<List<User>> GetAllAsync(CancellationToken cancellationToken = default);
        Task<(List<User> Items, int TotalCount)> GetPagedAsync(string? searchTerm, bool? isActive, int page, int pageSize, CancellationToken cancellationToken = default);
        void Add(User user);
        void Delete(User user);
    }
}
