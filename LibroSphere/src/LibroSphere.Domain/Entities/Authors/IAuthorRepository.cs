namespace LibroSphere.Domain.Entities.Authors
{
    public interface IAuthorRepository
    {
        Task<Author?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        Task<Author?> GetReadOnlyByIdAsync(Guid id, CancellationToken cancellationToken = default);
        Task<List<Author>> GetAllAsync(string? searchTerm = null, CancellationToken cancellationToken = default);
        void Add(Author author);
        void Delete(Author author);
    }
}
