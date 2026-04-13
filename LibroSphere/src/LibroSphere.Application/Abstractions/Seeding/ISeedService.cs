namespace LibroSphere.Application.Abstractions.Seeding;

public interface ISeedService
{
    Task<SeedResult> SeedGenresAsync(CancellationToken cancellationToken = default);
    Task<SeedResult> SeedCatalogAsync(CancellationToken cancellationToken = default);
}
