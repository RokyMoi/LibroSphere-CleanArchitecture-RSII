using LibroSphere.Domain.Entities.Books;

namespace LibroSphere.Application.Abstractions.Recommendations
{
    public interface IBookRecommendationService
    {
        Task<List<Book>> GetRecommendationsForUserAsync(Guid userId, int take = 5, CancellationToken cancellationToken = default);
    }
}
