namespace LibroSphere.Domain.Entities.Books
{
    public interface IBookRepository
    {
        Task<Book?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        Task<Book?> GetReadOnlyByIdAsync(Guid id, CancellationToken cancellationToken = default);
        Task<Book?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default);
        Task<Book?> GetByIdWithDetailsForUpdateAsync(Guid id, CancellationToken cancellationToken = default);
        Task<List<Book>> GetByIdsWithDetailsAsync(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken = default);
        Task<List<Book>> GetAllAsync(CancellationToken cancellationToken = default);
        Task<List<Book>> SearchAsync(string? searchTerm, Guid? authorId, Guid? genreId, decimal? minPrice = null, decimal? maxPrice = null, double? minRating = null, CancellationToken cancellationToken = default);
        Task<(List<Book> Items, int TotalCount)> SearchPagedAsync(string? searchTerm, Guid? authorId, Guid? genreId, decimal? minPrice, decimal? maxPrice, double? minRating, int page, int pageSize, CancellationToken cancellationToken = default);
        void ReplaceGenres(Book book, IReadOnlyCollection<Genre.Genre> genres);
        void Add(Book book);
        void Delete(Book book);
    }
}
