namespace LibroSphere.Domain.Entities.Users
{
    public interface IUserRepository
    {
        Task<User?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
        Task<List<User>> GetAllAsync(CancellationToken cancellationToken = default);
        void Add(User user);
        void Delete(User user);
    }
}
