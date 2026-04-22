namespace LibroSphere.Application.Abstractions.Notifications;

public interface IAdminNoteService
{
    Task<IReadOnlyCollection<AdminNoteDto>> GetLatestAsync(int take = 20, CancellationToken cancellationToken = default);
    Task<AdminNoteDto> CreateAsync(string title, string text, string imageUrl, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(string id, CancellationToken cancellationToken = default);
}

public sealed record AdminNoteDto(
    string Id,
    string Title,
    string Text,
    string ImageUrl,
    DateTime CreatedOnUtc);
