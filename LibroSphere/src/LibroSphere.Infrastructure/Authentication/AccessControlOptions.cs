namespace LibroSphere.Infrastructure.Authentication;

public sealed class AccessControlOptions
{
    public const string SectionName = "AccessControl";

    public List<string> AdminEmails { get; init; } = new();
    public bool SeedDefaultAdmin { get; init; }
    public string DefaultAdminFirstName { get; init; } = string.Empty;
    public string DefaultAdminLastName { get; init; } = string.Empty;
    public string DefaultAdminEmail { get; init; } = string.Empty;
    public string DefaultAdminPassword { get; init; } = string.Empty;
    public bool SeedDefaultUser { get; init; }
    public string DefaultUserFirstName { get; init; } = string.Empty;
    public string DefaultUserLastName { get; init; } = string.Empty;
    public string DefaultUserEmail { get; init; } = string.Empty;
    public string DefaultUserPassword { get; init; } = string.Empty;
}
