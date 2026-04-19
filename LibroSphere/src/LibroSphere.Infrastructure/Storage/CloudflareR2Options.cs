namespace LibroSphere.Infrastructure.Storage;

internal sealed class CloudflareR2Options
{
    public const string SectionName = "CloudflareR2";

    public string AccountEndpoint { get; init; } = string.Empty;
    public string BucketName { get; init; } = "librosphere";
    public string AccessKeyId { get; init; } = string.Empty;
    public string SecretAccessKey { get; init; } = string.Empty;
    public int SignedUrlMinutes { get; init; } = 30;
}
