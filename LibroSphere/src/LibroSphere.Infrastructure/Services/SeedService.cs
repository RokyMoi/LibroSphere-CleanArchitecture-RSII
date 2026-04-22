using LibroSphere.Application.Abstractions.Seeding;
using LibroSphere.Domain.Abstractions.Clock;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.Shared;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Infrastructure.Clock;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Services;

internal sealed class SeedService : ISeedService
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IDateTimeProvider _dateTimeProvider = new DateTimeProvider();

    public SeedService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<SeedResult> SeedGenresAsync(CancellationToken cancellationToken = default)
    {
        var genresToSeed = new[]
        {
            "Fiction",
            "Non-Fiction",
            "Fantasy",
            "Science Fiction",
            "Mystery",
            "Thriller",
            "Romance",
            "Historical Fiction",
            "Biography",
            "Memoir",
            "Self-Help",
            "Business",
            "Psychology",
            "Philosophy",
            "Poetry",
            "Young Adult",
            "Horror",
            "Adventure",
            "Classic",
            "Drama"
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
        var users = await _dbContext.Set<User>().ToListAsync(cancellationToken);

        var authorsCreated = 0;
        var booksCreated = 0;

        var programming = genres.First(x => x.Name.Value.Equals("Non-Fiction", StringComparison.OrdinalIgnoreCase));
        var classic = genres.First(x => x.Name.Value.Equals("Classic", StringComparison.OrdinalIgnoreCase));
        var philosophy = genres.First(x => x.Name.Value.Equals("Philosophy", StringComparison.OrdinalIgnoreCase));
        var business = genres.First(x => x.Name.Value.Equals("Business", StringComparison.OrdinalIgnoreCase));
        var fantasy = genres.First(x => x.Name.Value.Equals("Fantasy", StringComparison.OrdinalIgnoreCase));

        var authorDefinitions = new[]
        {
            new
            {
                Name = "David J. Eck",
                Biography = "Computer science educator known for clear, practical and beginner-friendly Java instruction."
            },
            new
            {
                Name = "Harper Lee",
                Biography = "American novelist whose work became one of the defining classics of modern literature."
            },
            new
            {
                Name = "Marcus Aurelius",
                Biography = "Roman emperor and Stoic philosopher remembered for timeless reflections on discipline and virtue."
            },
            new
            {
                Name = "Robert T. Kiyosaki",
                Biography = "Entrepreneur and author focused on financial literacy, assets and personal investing mindset."
            },
            new
            {
                Name = "Lewis Carroll",
                Biography = "English author and mathematician celebrated for imaginative fantasy and playful language."
            }
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

        var reviewerDefinitions = new[]
        {
            new { FirstName = "Mila", LastName = "Thompson", Email = "mila.thompson.seed@librosphere.test" },
            new { FirstName = "Noah", LastName = "Carter", Email = "noah.carter.seed@librosphere.test" },
            new { FirstName = "Emma", LastName = "Brooks", Email = "emma.brooks.seed@librosphere.test" },
            new { FirstName = "Liam", LastName = "Parker", Email = "liam.parker.seed@librosphere.test" }
        };

        foreach (var definition in reviewerDefinitions)
        {
            if (users.Any(x => x.UserEmail.Value.Equals(definition.Email, StringComparison.OrdinalIgnoreCase)))
            {
                continue;
            }

            var user = User.Create(
                new FirstName(definition.FirstName),
                new LastName(definition.LastName),
                new Email(definition.Email),
                _dateTimeProvider);

            await _dbContext.Set<User>().AddAsync(user, cancellationToken);
            users.Add(user);
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        var bookDefinitions = new[]
        {
            new
            {
                Title = "Java Programming",
                Description = "A practical introduction to Java that takes readers from language fundamentals to object-oriented thinking and structured problem solving.",
                Price = 24.99m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/javanotes5.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/javabook.jpg",
                AuthorName = "David J. Eck",
                Genres = new[] { programming }
            },
            new
            {
                Title = "To Kill a Mockingbird",
                Description = "A moving and deeply human novel about innocence, prejudice, justice and moral courage in a small Southern town.",
                Price = 18.50m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/ToKillAmockingBird.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/To%20Kill%20a%20Mocking%20Bird%20Harper%20Lee.jpg",
                AuthorName = "Harper Lee",
                Genres = new[] { classic }
            },
            new
            {
                Title = "Meditations",
                Description = "A classic collection of Stoic reflections on self-control, purpose, adversity and how to live with calm clarity.",
                Price = 14.20m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/Marcus-Aurelius-Meditations.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/Marcus%20Aurelius.jpg",
                AuthorName = "Marcus Aurelius",
                Genres = new[] { philosophy }
            },
            new
            {
                Title = "Rich Dad Poor Dad",
                Description = "A popular personal finance book centered on money mindset, assets, cash flow, risk and long-term financial independence.",
                Price = 17.80m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/RichDadPoorDad.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/Robert%20Kiyosaki.jpg",
                AuthorName = "Robert T. Kiyosaki",
                Genres = new[] { business }
            },
            new
            {
                Title = "Alice in Wonderland",
                Description = "A whimsical fantasy adventure through a curious dreamlike world full of strange logic, vivid characters and playful imagination.",
                Price = 12.90m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/AliceInWonderLand.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/aliceInWonderland.jpg",
                AuthorName = "Lewis Carroll",
                Genres = new[] { fantasy }
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

        var books = await _dbContext.Set<Book>().ToListAsync(cancellationToken);
        var existingReviews = await _dbContext
            .Set<Review>()
            .Select(x => new { x.UserId, x.BookId })
            .ToListAsync(cancellationToken);

        var reviewDefinitions = new[]
        {
            new
            {
                ReviewerEmail = "mila.thompson.seed@librosphere.test",
                BookTitle = "Java Programming",
                Rating = 5,
                Comment = "Clear explanations and practical examples make this a strong programming seed title."
            },
            new
            {
                ReviewerEmail = "noah.carter.seed@librosphere.test",
                BookTitle = "Java Programming",
                Rating = 4,
                Comment = "Very solid for beginners and still useful later when revisiting Java fundamentals."
            },
            new
            {
                ReviewerEmail = "emma.brooks.seed@librosphere.test",
                BookTitle = "Java Programming",
                Rating = 5,
                Comment = "Excellent technical starter book and perfect for testing non-fiction coding recommendations."
            },

            new
            {
                ReviewerEmail = "mila.thompson.seed@librosphere.test",
                BookTitle = "To Kill a Mockingbird",
                Rating = 5,
                Comment = "Compassionate, sharp and timeless, with memorable characters and emotional weight."
            },
            new
            {
                ReviewerEmail = "liam.parker.seed@librosphere.test",
                BookTitle = "To Kill a Mockingbird",
                Rating = 4,
                Comment = "A powerful literary classic that deserves its place in the catalog."
            },
            new
            {
                ReviewerEmail = "emma.brooks.seed@librosphere.test",
                BookTitle = "To Kill a Mockingbird",
                Rating = 5,
                Comment = "One of the strongest seed choices for classic fiction and courtroom drama readers."
            },

            new
            {
                ReviewerEmail = "noah.carter.seed@librosphere.test",
                BookTitle = "Meditations",
                Rating = 5,
                Comment = "Short, reflective and full of practical wisdom that feels relevant even now."
            },
            new
            {
                ReviewerEmail = "emma.brooks.seed@librosphere.test",
                BookTitle = "Meditations",
                Rating = 4,
                Comment = "A strong philosophy seed with plenty of concise passages worth revisiting."
            },
            new
            {
                ReviewerEmail = "liam.parker.seed@librosphere.test",
                BookTitle = "Meditations",
                Rating = 5,
                Comment = "Great for generating a distinct philosophy preference signal in recommendations."
            },

            new
            {
                ReviewerEmail = "mila.thompson.seed@librosphere.test",
                BookTitle = "Rich Dad Poor Dad",
                Rating = 4,
                Comment = "Accessible and motivating, especially for readers getting into finance and money mindset."
            },
            new
            {
                ReviewerEmail = "noah.carter.seed@librosphere.test",
                BookTitle = "Rich Dad Poor Dad",
                Rating = 3,
                Comment = "Useful as an entry point for business readers even if it is more inspirational than technical."
            },
            new
            {
                ReviewerEmail = "liam.parker.seed@librosphere.test",
                BookTitle = "Rich Dad Poor Dad",
                Rating = 4,
                Comment = "A good business seed title that gives the engine a clearly different audience signal."
            },

            new
            {
                ReviewerEmail = "emma.brooks.seed@librosphere.test",
                BookTitle = "Alice in Wonderland",
                Rating = 5,
                Comment = "Inventive, playful and iconic, with fantasy energy that stands apart from the other books."
            },
            new
            {
                ReviewerEmail = "mila.thompson.seed@librosphere.test",
                BookTitle = "Alice in Wonderland",
                Rating = 4,
                Comment = "Whimsical and imaginative, ideal for a lighter classic fantasy option in recommendations."
            },
            new
            {
                ReviewerEmail = "noah.carter.seed@librosphere.test",
                BookTitle = "Alice in Wonderland",
                Rating = 4,
                Comment = "Adds variety to the catalog and helps the recommendation system test genre diversity."
            }
        };

        foreach (var definition in reviewDefinitions)
        {
            var reviewer = users.FirstOrDefault(
                x => x.UserEmail.Value.Equals(definition.ReviewerEmail, StringComparison.OrdinalIgnoreCase));
            var book = books.FirstOrDefault(
                x => x.Title.Value.Equals(definition.BookTitle, StringComparison.OrdinalIgnoreCase));

            if (reviewer is null || book is null)
            {
                continue;
            }

            if (existingReviews.Any(x => x.UserId == reviewer.Id && x.BookId == book.Id))
            {
                continue;
            }

            var review = Review.Create(reviewer.Id, book.Id, definition.Rating, definition.Comment);
            await _dbContext.Set<Review>().AddAsync(review, cancellationToken);
            existingReviews.Add(new { UserId = reviewer.Id, BookId = book.Id });
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return new SeedResult(
            genreResult.GenresCreated,
            authorsCreated,
            booksCreated,
            genreResult.HasChanges || authorsCreated > 0 || booksCreated > 0);
    }
}
