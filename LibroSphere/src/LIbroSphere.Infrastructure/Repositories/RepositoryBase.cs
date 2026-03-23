
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Users;
using LIbroSphere.Infrastructure;
using Microsoft.EntityFrameworkCore;


namespace LibroSphere.Infrastructure.Repositories;

internal abstract class RepositoryBase<T>
    where T : BaseEntity
{
    protected readonly ApplicationDbContext DbContext;

    protected RepositoryBase(ApplicationDbContext dbContext)
    {
        DbContext = dbContext;
    }
  
    public async Task<T?> GetAsyncById(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        return await DbContext
            .Set<T>()
            .FirstOrDefaultAsync(user => user.Id == id, cancellationToken);
    }

    public void Add(T entity)
    {
        DbContext.Set<T>().Add(entity);
    }
}