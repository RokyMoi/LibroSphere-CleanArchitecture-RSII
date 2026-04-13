namespace LibroSphere.Application.Abstractions.Seeding;

public sealed record SeedResult(
    int GenresCreated,
    int AuthorsCreated,
    int BooksCreated,
    bool HasChanges);
