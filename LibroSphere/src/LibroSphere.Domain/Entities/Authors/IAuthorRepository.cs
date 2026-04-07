namespace LibroSphere.Domain.Entities.Authors
{
    public interface IAuthorRepository
    {
        Task<Author?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        Task<List<Author>> GetAllAsync(CancellationToken cancellationToken = default);
        void Add(Author author);
        void Delete(Author author);
    }
}
