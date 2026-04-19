using LibroSphere.Application.Abstractions.Seeding;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Shared;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Services;

internal sealed class SeedService : ISeedService
{
    private readonly ApplicationDbContext _dbContext;

    public SeedService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<SeedResult> SeedGenresAsync(CancellationToken cancellationToken = default)
    {
        var genresToSeed = new[]
        {
            "Fiction",
            "Non-Fiction"
        };

        var existingGenreNames = await _dbContext
            .Set<Genre>()
            .Select(x => x.Name.Value)
            .ToListAsync(cancellationToken);

        var createdGenres = 0;

        foreach (var genreName in genresToSeed)
        {
            if (existingGenreNames.Any(x => x.Equals(genreName, StringComparison.OrdinalIgnoreCase)))
            {
                continue;
            }

            await _dbContext.Set<Genre>().AddAsync(
                Genre.Create(new LibroSphere.Domain.Entities.Books.Genre.Name(genreName)),
                cancellationToken);

            createdGenres++;
        }

        if (createdGenres > 0)
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return new SeedResult(createdGenres, 0, 0, createdGenres > 0);
    }

    public async Task<SeedResult> SeedCatalogAsync(CancellationToken cancellationToken = default)
    {
        var genreResult = await SeedGenresAsync(cancellationToken);

        var authors = await _dbContext.Set<Author>().ToListAsync(cancellationToken);
        var genres = await _dbContext.Set<Genre>().ToListAsync(cancellationToken);

        var authorsCreated = 0;
        var booksCreated = 0;

        var fiction = genres.First(x => x.Name.Value.Equals("Fiction", StringComparison.OrdinalIgnoreCase));
        var nonFiction = genres.First(x => x.Name.Value.Equals("Non-Fiction", StringComparison.OrdinalIgnoreCase));

        var authorDefinitions = new[]
        {
            new { Name = "George Orwell", Biography = "English novelist, essayist and critic." },
            new { Name = "James Clear", Biography = "Writer focused on habits, systems and self-improvement." },
            new { Name = "Harper Lee", Biography = "American novelist best known for classic courtroom drama." }
        };

        foreach (var definition in authorDefinitions)
        {
            if (authors.Any(x => x.Name.Value.Equals(definition.Name, StringComparison.OrdinalIgnoreCase)))
            {
                continue;
            }

            var author = Author.Create(
                new LibroSphere.Domain.Entities.Authors.Name(definition.Name),
                new Biography(definition.Biography));

            await _dbContext.Set<Author>().AddAsync(author, cancellationToken);
            authors.Add(author);
            authorsCreated++;
        }

        if (authorsCreated > 0)
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        var bookDefinitions = new[]
        {
            new
            {
                Title = "1984",
                Description = "A dystopian novel about surveillance, truth and authoritarian control.",
                Price = 14.99m,
                PdfLink = "https://example.com/books/1984.pdf",
                ImageLink = "https://example.com/books/1984.jpg",
                AuthorName = "George Orwell",
                Genres = new[] { fiction }
            },
            new
            {
                Title = "Animal Farm",
                Description = "A political allegory told through a rebellion on a farm.",
                Price = 12.50m,
                PdfLink = "https://example.com/books/animal-farm.pdf",
                ImageLink = "https://example.com/books/animal-farm.jpg",
                AuthorName = "George Orwell",
                Genres = new[] { fiction }
            },
            new
            {
                Title = "Atomic Habits",
                Description = "Practical guidance on building better habits through small systems.",
                Price = 18.00m,
                PdfLink = "https://example.com/books/atomic-habits.pdf",
                ImageLink = "https://example.com/books/atomic-habits.jpg",
                AuthorName = "James Clear",
                Genres = new[] { nonFiction }
            },
            new
            {
                Title = "To Kill a Mockingbird",
                Description = "A coming-of-age courtroom novel about justice and moral courage.",
                Price = 16.25m,
                PdfLink = "https://example.com/books/to-kill-a-mockingbird.pdf",
                ImageLink = "https://example.com/books/to-kill-a-mockingbird.jpg",
                AuthorName = "Harper Lee",
                Genres = new[] { fiction }
            }
        };

        var existingBookTitles = await _dbContext
            .Set<Book>()
            .Select(x => x.Title.Value)
            .ToListAsync(cancellationToken);

        foreach (var definition in bookDefinitions)
        {
            if (existingBookTitles.Any(x => x.Equals(definition.Title, StringComparison.OrdinalIgnoreCase)))
            {
                continue;
            }

            var author = authors.First(x => x.Name.Value.Equals(definition.AuthorName, StringComparison.OrdinalIgnoreCase));

            var book = Book.MakeABook(
                new Title(definition.Title),
                new Description(definition.Description),
                new Money(definition.Price, Currency.FromCode("USD")),
                new BookLinks(definition.PdfLink, definition.ImageLink),
                author.Id);

            await _dbContext.Set<Book>().AddAsync(book, cancellationToken);

            foreach (var genre in definition.Genres)
            {
                await _dbContext.Set<BookGenre>().AddAsync(BookGenre.Create(book, genre), cancellationToken);
            }

            booksCreated++;
        }

        if (booksCreated > 0)
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return new SeedResult(
            genreResult.GenresCreated,
            authorsCreated,
            booksCreated,
            genreResult.HasChanges || authorsCreated > 0 || booksCreated > 0);
    }
}
