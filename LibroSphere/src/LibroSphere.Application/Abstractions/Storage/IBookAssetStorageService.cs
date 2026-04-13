namespace LibroSphere.Application.Abstractions.Storage;

public interface IBookAssetStorageService
{
    Task<BookAssetUploadResult> UploadPdfAsync(
        Stream stream,
        string fileName,
        string contentType,
        CancellationToken cancellationToken = default);

    Task<BookAssetUploadResult> UploadImageAsync(
        Stream stream,
        string fileName,
        string contentType,
        CancellationToken cancellationToken = default);

    Task<string> GetPdfReadUrlAsync(
        string storedValue,
        CancellationToken cancellationToken = default);

    Task<string?> GetImageUrlAsync(
        string? storedValue,
        CancellationToken cancellationToken = default);

    bool IsManagedStorageKey(string storedValue);
}

public sealed record BookAssetUploadResult(string StoredValue);
