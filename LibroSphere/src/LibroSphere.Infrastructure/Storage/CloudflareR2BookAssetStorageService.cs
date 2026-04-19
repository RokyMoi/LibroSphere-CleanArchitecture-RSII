using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using LibroSphere.Application.Abstractions.Storage;
using Microsoft.Extensions.Options;

namespace LibroSphere.Infrastructure.Storage;

internal sealed class CloudflareR2BookAssetStorageService : IBookAssetStorageService
{
    private static readonly HashSet<string> AllowedImageContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp"
    };

    private readonly IAmazonS3 _s3Client;
    private readonly CloudflareR2Options _options;

    public CloudflareR2BookAssetStorageService(
        IOptions<CloudflareR2Options> options)
    {
        _options = options.Value;

        if (string.IsNullOrWhiteSpace(_options.AccountEndpoint))
        {
            throw new InvalidOperationException("Cloudflare R2 account endpoint is not configured.");
        }

        if (string.IsNullOrWhiteSpace(_options.AccessKeyId) ||
            string.IsNullOrWhiteSpace(_options.SecretAccessKey))
        {
            throw new InvalidOperationException("Cloudflare R2 credentials are not configured.");
        }

        if (string.IsNullOrWhiteSpace(_options.BucketName))
        {
            throw new InvalidOperationException("Cloudflare R2 bucket name is not configured.");
        }

        var config = new AmazonS3Config
        {
            ServiceURL = _options.AccountEndpoint,
            ForcePathStyle = true,
            AuthenticationRegion = "auto",
            SignatureVersion = "4",
            Timeout = TimeSpan.FromSeconds(30)
        };

        _s3Client = new AmazonS3Client(
            new BasicAWSCredentials(_options.AccessKeyId, _options.SecretAccessKey),
            config);
    }

    public Task<string?> GetImageUrlAsync(string? storedValue, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(storedValue))
        {
            return Task.FromResult<string?>(null);
        }

        return Task.FromResult<string?>(ResolveAssetUrl(storedValue.Trim(), TimeSpan.FromMinutes(_options.SignedUrlMinutes)));
    }

    public Task<string> GetPdfReadUrlAsync(string storedValue, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(storedValue))
        {
            throw new InvalidOperationException("Book PDF storage value is not configured.");
        }

        return Task.FromResult(ResolveAssetUrl(storedValue.Trim(), TimeSpan.FromMinutes(_options.SignedUrlMinutes)));
    }

    public bool IsManagedStorageKey(string storedValue)
    {
        if (string.IsNullOrWhiteSpace(storedValue))
        {
            return false;
        }

        return !Uri.TryCreate(storedValue, UriKind.Absolute, out _);
    }

    public Task<BookAssetUploadResult> UploadImageAsync(
        Stream stream,
        string fileName,
        string contentType,
        CancellationToken cancellationToken = default) =>
        UploadAsync("books/images", stream, fileName, contentType, AllowedImageContentTypes, cancellationToken);

    public Task<BookAssetUploadResult> UploadPdfAsync(
        Stream stream,
        string fileName,
        string contentType,
        CancellationToken cancellationToken = default) =>
        UploadAsync("books/pdfs", stream, fileName, contentType, new[] { "application/pdf" }, cancellationToken);

    private async Task<BookAssetUploadResult> UploadAsync(
        string prefix,
        Stream stream,
        string fileName,
        string contentType,
        IEnumerable<string> allowedContentTypes,
        CancellationToken cancellationToken)
    {
        if (stream is null)
        {
            throw new ArgumentNullException(nameof(stream));
        }

        if (string.IsNullOrWhiteSpace(fileName))
        {
            throw new InvalidOperationException("File name is required.");
        }

        if (string.IsNullOrWhiteSpace(contentType) ||
            !allowedContentTypes.Contains(contentType, StringComparer.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Unsupported file content type.");
        }

        var extension = Path.GetExtension(fileName);
        var objectKey = $"{prefix}/{DateTime.UtcNow:yyyy/MM}/{Guid.NewGuid():N}{extension}";

        var request = new PutObjectRequest
        {
            BucketName = _options.BucketName,
            Key = objectKey,
            InputStream = stream,
            ContentType = contentType,
            AutoCloseStream = false,
            AutoResetStreamPosition = false,
            DisablePayloadSigning = true,
            DisableDefaultChecksumValidation = true,
            UseChunkEncoding = false
        };

        await _s3Client.PutObjectAsync(request, cancellationToken);
        return new BookAssetUploadResult(objectKey);
    }

    private string ResolveAssetUrl(string storedValue, TimeSpan expiresIn)
    {
        if (!IsManagedStorageKey(storedValue))
        {
            return storedValue;
        }

        var request = new GetPreSignedUrlRequest
        {
            BucketName = _options.BucketName,
            Key = storedValue,
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow.Add(expiresIn)
        };

        return _s3Client.GetPreSignedURL(request);
    }
}
