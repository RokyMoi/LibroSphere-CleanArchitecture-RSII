namespace LibroSphere.Application.Abstractions.Notifications;

public interface INewsService
{
    Task<IReadOnlyCollection<NewsItemDto>> GetLatestAsync(int take = 20, CancellationToken cancellationToken = default);
    Task<NewsItemDto> CreateAsync(string title, string text, string imageUrl, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(string id, CancellationToken cancellationToken = default);
}

public sealed record NewsItemDto(
    string Id,
    string Title,
    string Text,
    string ImageUrl,
    DateTime CreatedOnUtc);
