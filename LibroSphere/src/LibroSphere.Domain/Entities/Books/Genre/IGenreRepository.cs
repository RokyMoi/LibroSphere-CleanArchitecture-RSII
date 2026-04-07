namespace LibroSphere.Domain.Entities.Books.Genre
{
    public interface IGenreRepository
    {
        Task<Genre?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        Task<Genre?> GetByNameAsync(string name, CancellationToken cancellationToken = default);
        Task<List<Genre>> GetAllAsync(CancellationToken cancellationToken = default);
        Task<List<Genre>> GetByIdsAsync(IEnumerable<Guid> ids, CancellationToken cancellationToken = default);
        void Add(Genre genre);
    }
}
