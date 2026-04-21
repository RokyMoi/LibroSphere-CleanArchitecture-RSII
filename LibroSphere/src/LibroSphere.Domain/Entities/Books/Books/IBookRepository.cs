namespace LibroSphere.Domain.Entities.Books
{
    public interface IBookRepository
    {
        Task<Book?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        Task<Book?> GetReadOnlyByIdAsync(Guid id, CancellationToken cancellationToken = default);
        Task<Book?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default);
        Task<List<Book>> GetByIdsWithDetailsAsync(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken = default);
        Task<List<Book>> GetAllAsync(CancellationToken cancellationToken = default);
        Task<List<Book>> SearchAsync(string? searchTerm, Guid? authorId, Guid? genreId, CancellationToken cancellationToken = default);
        void ReplaceGenres(Book book, IReadOnlyCollection<Genre.Genre> genres);
        void Add(Book book);
        void Delete(Book book);
    }
}
