

namespace LibroSphere.Domain.Entities.ManyToMany.IRepositories
{
    public interface IUserBookRepository
    {
        Task<List<UserBook>> GetByEmailAsync(string email);
        Task<bool> HasAccessAsync(string email, Guid bookId);
        Task AddAsync(UserBook userBook);
        Task SaveChangesAsync();
    }
}