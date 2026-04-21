namespace LibroSphere.Domain.Entities.ManyToMany.IRepositories
{
    public interface IUserBookRepository
    {
        Task<List<UserBook>> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
        Task<bool> HasAccessAsync(string email, Guid bookId);
        Task AddAsync(UserBook userBook);
        Task RemoveAsync(UserBook userBook);
        Task SaveChangesAsync();
    }
}
