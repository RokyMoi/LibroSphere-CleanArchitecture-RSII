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
        var poetry = genres.First(x => x.Name.Value.Equals("Poetry", StringComparison.OrdinalIgnoreCase));
        var historicalFiction = genres.First(x => x.Name.Value.Equals("Historical Fiction", StringComparison.OrdinalIgnoreCase));
        var fiction = genres.First(x => x.Name.Value.Equals("Fiction", StringComparison.OrdinalIgnoreCase));
        var romance = genres.First(x => x.Name.Value.Equals("Romance", StringComparison.OrdinalIgnoreCase));

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
            },
            new
            {
                Name = "Fedor Dostojevski",
                Biography = "Russian novelist whose psychologically profound works explore morality, guilt, faith and the depths of the human soul."
            },
            new
            {
                Name = "Mesa Selimovic",
                Biography = "Bosnian and Yugoslav writer renowned for introspective novels examining identity, power, solitude and the human condition."
            },
            new
            {
                Name = "Jovan Ducic",
                Biography = "Serbian poet and diplomat regarded as one of the most refined lyric voices of his era."
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
            },
            new
            {
                Title = "Zlocin i kazna",
                Description = "A gripping psychological novel following a young man's descent into guilt and torment after committing a crime he believed he could justify.",
                Price = 19.99m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/dostojevski_zlocinikazna.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/zlocin-i-kazna.jpg",
                AuthorName = "Fedor Dostojevski",
                Genres = new[] { classic, philosophy }
            },
            new
            {
                Title = "Tvrdjava",
                Description = "A reflective novel about a war survivor seeking meaning, love and dignity in a society shaped by power, fear and moral compromise.",
                Price = 16.50m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/mesa-selimovic-tvrdjava.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/Tvrdjava_selimovi%C4%87.jpg",
                AuthorName = "Mesa Selimovic",
                Genres = new[] { classic, historicalFiction }
            },
            new
            {
                Title = "Tisine",
                Description = "An introspective novel exploring the quiet struggles of a man returning from war and confronting solitude, memory and inner conflict.",
                Price = 15.90m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/Tisine-Mesa-Selimovic.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/tisine_nova_knjiga.jpg",
                AuthorName = "Mesa Selimovic",
                Genres = new[] { classic, fiction }
            },
            new
            {
                Title = "Pjesme",
                Description = "A refined collection of lyric poetry celebrated for its elegance, musicality and meditations on love, beauty and the human spirit.",
                Price = 12.50m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/Jovan-Ducic-Pesme.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/JovanDucicPesme.jpg",
                AuthorName = "Jovan Ducic",
                Genres = new[] { poetry, classic }
            },
            new
            {
                Title = "Bijele noci",
                Description = "A tender and melancholic tale of a lonely dreamer who finds fleeting connection and heartbreak over a few unforgettable nights.",
                Price = 13.40m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/dostojevski-bele-noci_compressed.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/beleNoci.jfif",
                AuthorName = "Fedor Dostojevski",
                Genres = new[] { classic, romance }
            },
            new
            {
                Title = "Braca Karamazovi",
                Description = "A sweeping philosophical novel about faith, doubt, family and morality, centered on three brothers and the murder that binds their fates.",
                Price = 22.90m,
                PdfLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/pdfs/2026/04/Dostojevski%20-%20Bra%C4%87a%20Karamazovi.pdf",
                ImageLink = "https://pub-8f1c06c06115460a9c357fe92dbc674b.r2.dev/books/images/2026/04/braca-karamazovi-svezak-i.jpg",
                AuthorName = "Fedor Dostojevski",
                Genres = new[] { classic, philosophy }
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
            .ToListAsync(cancellationToken);

        var reviewsChanged = false;

        var reviewDefinitions = new[]
        {
            new
            {
                ReviewerEmail = "mila.thompson.seed@librosphere.test",
                BookTitle = "Java Programming",
                Rating = 5,
                Comment = "Probably the clearest intro to Java I've read. It explains the basics without talking down to you, and the examples actually help."
            },
            new
            {
                ReviewerEmail = "noah.carter.seed@librosphere.test",
                BookTitle = "Java Programming",
                Rating = 4,
                Comment = "Really good starting point if you're new to Java. A few chapters feel a bit dry, but overall it's practical and easy to follow."
            },
            new
            {
                ReviewerEmail = "emma.brooks.seed@librosphere.test",
                BookTitle = "Java Programming",
                Rating = 5,
                Comment = "I liked that it focuses on understanding how the language works instead of just dumping syntax. Solid beginner book."
            },

            new
            {
                ReviewerEmail = "mila.thompson.seed@librosphere.test",
                BookTitle = "To Kill a Mockingbird",
                Rating = 5,
                Comment = "This one really stays with you. Scout's voice feels so real, and the story handles difficult themes with a lot of heart."
            },
            new
            {
                ReviewerEmail = "liam.parker.seed@librosphere.test",
                BookTitle = "To Kill a Mockingbird",
                Rating = 4,
                Comment = "A deserved classic. It starts gently, but by the end it hits hard and gives you a lot to think about."
            },
            new
            {
                ReviewerEmail = "emma.brooks.seed@librosphere.test",
                BookTitle = "To Kill a Mockingbird",
                Rating = 5,
                Comment = "Beautifully written and emotionally sharp. I can see why people return to it years later."
            },

            new
            {
                ReviewerEmail = "noah.carter.seed@librosphere.test",
                BookTitle = "Meditations",
                Rating = 5,
                Comment = "I expected something distant and academic, but a lot of it feels surprisingly direct and useful in everyday life."
            },
            new
            {
                ReviewerEmail = "emma.brooks.seed@librosphere.test",
                BookTitle = "Meditations",
                Rating = 4,
                Comment = "Some passages are repetitive, but when it clicks it's incredibly grounding. Best read slowly rather than all at once."
            },
            new
            {
                ReviewerEmail = "liam.parker.seed@librosphere.test",
                BookTitle = "Meditations",
                Rating = 5,
                Comment = "Not a flashy book, but I kept highlighting lines. It has that rare quality of making you pause and reset."
            },

            new
            {
                ReviewerEmail = "mila.thompson.seed@librosphere.test",
                BookTitle = "Rich Dad Poor Dad",
                Rating = 4,
                Comment = "Very easy to read and definitely motivating. I don't agree with every point, but it does make you think differently about money."
            },
            new
            {
                ReviewerEmail = "noah.carter.seed@librosphere.test",
                BookTitle = "Rich Dad Poor Dad",
                Rating = 3,
                Comment = "Useful as a mindset book more than a practical guide. Worth reading once, just don't expect detailed financial advice."
            },
            new
            {
                ReviewerEmail = "liam.parker.seed@librosphere.test",
                BookTitle = "Rich Dad Poor Dad",
                Rating = 4,
                Comment = "A bit repetitive in places, but it explains assets, liabilities and long-term thinking in a way that's easy to remember."
            },

            new
            {
                ReviewerEmail = "emma.brooks.seed@librosphere.test",
                BookTitle = "Alice in Wonderland",
                Rating = 5,
                Comment = "Completely strange in the best way. It feels playful on the surface, but there's a lot of cleverness underneath."
            },
            new
            {
                ReviewerEmail = "mila.thompson.seed@librosphere.test",
                BookTitle = "Alice in Wonderland",
                Rating = 4,
                Comment = "Funny, chaotic and imaginative. It's one of those books where the dream logic is half the fun."
            },
            new
            {
                ReviewerEmail = "noah.carter.seed@librosphere.test",
                BookTitle = "Alice in Wonderland",
                Rating = 4,
                Comment = "Not really plot-heavy, but the mood and characters carry it. A charming read if you lean into the weirdness."
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

            var existingReview = existingReviews.FirstOrDefault(x => x.UserId == reviewer.Id && x.BookId == book.Id);

            if (existingReview is not null)
            {
                if (existingReview.Rating != definition.Rating ||
                    !string.Equals(existingReview.Comment, definition.Comment, StringComparison.Ordinal))
                {
                    existingReview.Update(definition.Rating, definition.Comment);
                    reviewsChanged = true;
                }

                continue;
            }

            var review = Review.Create(reviewer.Id, book.Id, definition.Rating, definition.Comment);
            await _dbContext.Set<Review>().AddAsync(review, cancellationToken);
            existingReviews.Add(review);
            reviewsChanged = true;
        }

        if (reviewsChanged)
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return new SeedResult(
            genreResult.GenresCreated,
            authorsCreated,
            booksCreated,
            genreResult.HasChanges || authorsCreated > 0 || booksCreated > 0 || reviewsChanged);
    }
}
