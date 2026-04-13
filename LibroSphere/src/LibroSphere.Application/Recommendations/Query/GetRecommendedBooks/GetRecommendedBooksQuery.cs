using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Recommendations.Query.GetRecommendedBooks
{
    public sealed record GetRecommendedBooksQuery(Guid UserId, int Take = 5) : IQuery<List<RecommendedBookResponse>>;
}
