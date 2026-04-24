using Dapper;
using LibroSphere.Application.Abstractions.Data;
using LibroSphere.Application.Abstractions.Recommendations;
using LibroSphere.Domain.Entities.Books;

namespace LibroSphere.Infrastructure.Services
{
    internal sealed class BookRecommendationService : IBookRecommendationService
    {
        private const int MaxTake = 20;
        private const int CandidatePoolSize = 120;

        private readonly ISqlConnectionFactory _sqlConnectionFactory;
        private readonly IBookRepository _bookRepository;

        public BookRecommendationService(
            ISqlConnectionFactory sqlConnectionFactory,
            IBookRepository bookRepository)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
            _bookRepository = bookRepository;
        }

        public async Task<List<Book>> GetRecommendationsForUserAsync(
            Guid userId,
            int take = 5,
            CancellationToken cancellationToken = default)
        {
            var normalizedTake = Math.Clamp(take, 1, MaxTake);

            using var connection = _sqlConnectionFactory.CreateConnection();

            var interactionRows = (await connection.QueryAsync<InteractionSignalRow>(
                new CommandDefinition(
                    InteractionSignalsSql,
                    new { UserId = userId },
                    cancellationToken: cancellationToken)))
                .AsList();

            var candidateRows = (await connection.QueryAsync<CandidateBookRow>(
                new CommandDefinition(
                    CandidateBooksSql,
                    new { UserId = userId, CandidatePoolSize },
                    cancellationToken: cancellationToken)))
                .AsList();

            if (candidateRows.Count == 0)
            {
                return new List<Book>();
            }

            var profile = UserPreferenceProfile.Build(interactionRows);
            var rankedBookIds = RankCandidates(candidateRows, profile, normalizedTake);
            var books = await _bookRepository.GetByIdsWithDetailsAsync(rankedBookIds, cancellationToken);
            var booksById = books.ToDictionary(book => book.Id);

            return rankedBookIds
                .Where(booksById.ContainsKey)
                .Select(bookId => booksById[bookId])
                .ToList();
        }

        private static List<Guid> RankCandidates(
            IReadOnlyCollection<CandidateBookRow> candidateRows,
            UserPreferenceProfile profile,
            int take)
        {
            var candidateLookup = new Dictionary<Guid, CandidateAccumulator>();

            foreach (var row in candidateRows)
            {
                if (!candidateLookup.TryGetValue(row.BookId, out var candidate))
                {
                    candidate = new CandidateAccumulator(
                        row.BookId,
                        row.AuthorId,
                        row.AverageRating,
                        row.ReviewCount,
                        row.PurchaseCount,
                        row.WishlistCount,
                        row.CartCount);

                    candidateLookup[row.BookId] = candidate;
                }

                if (row.GenreId.HasValue)
                {
                    candidate.GenreIds.Add(row.GenreId.Value);
                }
            }

            var candidates = candidateLookup.Values
                .Select(candidate =>
                {
                    var genreIds = candidate.GenreIds.ToList();

                    return new CandidateScore(
                        candidate.BookId,
                        candidate.AuthorId,
                        genreIds,
                        ComputeBaseScore(
                            candidate.AuthorId,
                            genreIds,
                            candidate.AverageRating,
                            candidate.ReviewCount,
                            candidate.PurchaseCount,
                            candidate.WishlistCount,
                            candidate.CartCount,
                            profile));
                })
                .ToList();

            return profile.HasSignals
                ? SelectPersonalizedBooks(candidates, profile, take)
                : SelectColdStartBooks(candidates, take);
        }

        private static double ComputeBaseScore(
            Guid authorId,
            IReadOnlyCollection<Guid> genreIds,
            double averageRating,
            int reviewCount,
            int purchaseCount,
            int wishlistCount,
            int cartCount,
            UserPreferenceProfile profile)
        {
            var genreScore = 0d;

            if (genreIds.Count > 0)
            {
                foreach (var genreId in genreIds)
                {
                    genreScore += profile.GetGenreWeight(genreId);
                }

                genreScore /= Math.Sqrt(genreIds.Count);
            }

            var authorScore = profile.GetAuthorWeight(authorId) * 0.65;
            var qualityScore =
                (averageRating * 0.7) +
                (Log1p(reviewCount) * 0.55) +
                (Log1p(purchaseCount) * 0.9) +
                (Log1p(wishlistCount) * 0.35) +
                (Log1p(cartCount) * 0.25);

            var explorationBoost = genreIds.Any(genreId => !profile.PositiveGenres.Contains(genreId))
                ? 0.35
                : 0;

            return genreScore + authorScore + qualityScore + explorationBoost;
        }

        private static List<Guid> SelectPersonalizedBooks(
            IReadOnlyCollection<CandidateScore> candidates,
            UserPreferenceProfile profile,
            int take)
        {
            var orderedCandidates = candidates
                .OrderByDescending(candidate => candidate.BaseScore + CandidateDiversityBonus(candidate, profile))
                .ThenBy(candidate => candidate.AuthorId)
                .ToList();

            return SelectWithDiversityGuardrails(
                orderedCandidates,
                take,
                candidate => candidate.GenreIds.Any(genreId => !profile.PositiveGenres.Contains(genreId)));
        }

        private static List<Guid> SelectColdStartBooks(
            IReadOnlyCollection<CandidateScore> candidates,
            int take)
        {
            var orderedCandidates = candidates
                .OrderByDescending(candidate => candidate.BaseScore + ColdStartDiversityBonus(candidate))
                .ThenBy(candidate => candidate.AuthorId)
                .ToList();

            return SelectWithDiversityGuardrails(
                orderedCandidates,
                take,
                candidate => candidate.GenreIds.Count > 0);
        }

        private static double CandidateDiversityBonus(
            CandidateScore candidate,
            UserPreferenceProfile profile)
        {
            var outsideTopComfortZone = candidate.GenreIds.Any(genreId => !profile.PositiveGenres.Contains(genreId))
                ? 0.55
                : 0;

            var multiGenreBonus = Math.Min(candidate.GenreIds.Count, 3) * 0.1;

            return outsideTopComfortZone + multiGenreBonus;
        }

        private static double ColdStartDiversityBonus(
            CandidateScore candidate)
        {
            if (candidate.GenreIds.Count == 0)
            {
                return 0;
            }

            return 1.15 + Math.Min(candidate.GenreIds.Count, 3) * 0.1;
        }

        private static List<Guid> SelectWithDiversityGuardrails(
            IReadOnlyList<CandidateScore> orderedCandidates,
            int take,
            Func<CandidateScore, bool> priorityPredicate)
        {
            var selected = new List<Guid>(take);
            var selectedBookIds = new HashSet<Guid>();
            var selectedGenreCounts = new Dictionary<Guid, int>();
            var selectedAuthorCounts = new Dictionary<Guid, int>();

            SelectCandidates(
                orderedCandidates,
                take,
                selected,
                selectedBookIds,
                selectedGenreCounts,
                selectedAuthorCounts,
                candidate =>
                    selectedAuthorCounts.GetValueOrDefault(candidate.AuthorId) == 0 &&
                    candidate.GenreIds.Any(genreId => !selectedGenreCounts.ContainsKey(genreId)) &&
                    priorityPredicate(candidate));

            SelectCandidates(
                orderedCandidates,
                take,
                selected,
                selectedBookIds,
                selectedGenreCounts,
                selectedAuthorCounts,
                candidate =>
                    selectedAuthorCounts.GetValueOrDefault(candidate.AuthorId) == 0 &&
                    candidate.GenreIds.Any(genreId => !selectedGenreCounts.ContainsKey(genreId)));

            SelectCandidates(
                orderedCandidates,
                take,
                selected,
                selectedBookIds,
                selectedGenreCounts,
                selectedAuthorCounts,
                candidate => selectedAuthorCounts.GetValueOrDefault(candidate.AuthorId) == 0);

            SelectCandidates(
                orderedCandidates,
                take,
                selected,
                selectedBookIds,
                selectedGenreCounts,
                selectedAuthorCounts,
                _ => true);

            return selected;
        }

        private static void SelectCandidates(
            IReadOnlyList<CandidateScore> orderedCandidates,
            int take,
            List<Guid> selected,
            HashSet<Guid> selectedBookIds,
            Dictionary<Guid, int> selectedGenreCounts,
            Dictionary<Guid, int> selectedAuthorCounts,
            Func<CandidateScore, bool> predicate)
        {
            foreach (var candidate in orderedCandidates)
            {
                if (selected.Count >= take)
                {
                    return;
                }

                if (selectedBookIds.Contains(candidate.BookId) || !predicate(candidate))
                {
                    continue;
                }

                selectedBookIds.Add(candidate.BookId);
                selected.Add(candidate.BookId);

                foreach (var genreId in candidate.GenreIds)
                {
                    selectedGenreCounts[genreId] = selectedGenreCounts.GetValueOrDefault(genreId) + 1;
                }

                selectedAuthorCounts[candidate.AuthorId] = selectedAuthorCounts.GetValueOrDefault(candidate.AuthorId) + 1;
            }
        }

        private static double Log1p(int value) => Math.Log(1 + Math.Max(0, value));

        private sealed record InteractionSignalRow(
            string SignalType,
            Guid BookId,
            Guid AuthorId,
            Guid? GenreId,
            double Weight);

        private sealed record CandidateBookRow(
            Guid BookId,
            Guid AuthorId,
            Guid? GenreId,
            double AverageRating,
            int ReviewCount,
            int PurchaseCount,
            int WishlistCount,
            int CartCount);

        private sealed record CandidateScore(
            Guid BookId,
            Guid AuthorId,
            IReadOnlyList<Guid> GenreIds,
            double BaseScore);

        private sealed class CandidateAccumulator
        {
            public CandidateAccumulator(
                Guid bookId,
                Guid authorId,
                double averageRating,
                int reviewCount,
                int purchaseCount,
                int wishlistCount,
                int cartCount)
            {
                BookId = bookId;
                AuthorId = authorId;
                AverageRating = averageRating;
                ReviewCount = reviewCount;
                PurchaseCount = purchaseCount;
                WishlistCount = wishlistCount;
                CartCount = cartCount;
            }

            public Guid BookId { get; }
            public Guid AuthorId { get; }
            public double AverageRating { get; }
            public int ReviewCount { get; }
            public int PurchaseCount { get; }
            public int WishlistCount { get; }
            public int CartCount { get; }
            public HashSet<Guid> GenreIds { get; } = new();
        }

        private sealed class UserPreferenceProfile
        {
            private UserPreferenceProfile(
                Dictionary<Guid, double> genreWeights,
                Dictionary<Guid, double> authorWeights,
                HashSet<Guid> positiveGenres)
            {
                GenreWeights = genreWeights;
                AuthorWeights = authorWeights;
                PositiveGenres = positiveGenres;
            }

            public Dictionary<Guid, double> GenreWeights { get; }
            public Dictionary<Guid, double> AuthorWeights { get; }
            public HashSet<Guid> PositiveGenres { get; }
            public bool HasSignals => GenreWeights.Count > 0 || AuthorWeights.Count > 0;

            public double GetGenreWeight(Guid genreId) => GenreWeights.GetValueOrDefault(genreId);

            public double GetAuthorWeight(Guid authorId) => AuthorWeights.GetValueOrDefault(authorId);

            public static UserPreferenceProfile Build(IReadOnlyCollection<InteractionSignalRow> rows)
            {
                var genreWeights = new Dictionary<Guid, double>();
                var authorWeights = new Dictionary<Guid, double>();

                var groupedSignals = rows
                    .GroupBy(row => new { row.SignalType, row.BookId, row.AuthorId, row.Weight });

                foreach (var signal in groupedSignals)
                {
                    authorWeights[signal.Key.AuthorId] = authorWeights.GetValueOrDefault(signal.Key.AuthorId) + signal.Key.Weight;

                    var genreIds = signal
                        .Where(row => row.GenreId.HasValue)
                        .Select(row => row.GenreId!.Value)
                        .Distinct()
                        .ToList();

                    if (genreIds.Count == 0)
                    {
                        continue;
                    }

                    var genreWeight = signal.Key.Weight / genreIds.Count;

                    foreach (var genreId in genreIds)
                    {
                        genreWeights[genreId] = genreWeights.GetValueOrDefault(genreId) + genreWeight;
                    }
                }

                var positiveGenres = genreWeights
                    .Where(entry => entry.Value > 0.75)
                    .Select(entry => entry.Key)
                    .ToHashSet();

                return new UserPreferenceProfile(genreWeights, authorWeights, positiveGenres);
            }
        }

        private const string InteractionSignalsSql = """
            WITH PurchaseSignals AS (
                SELECT
                    'purchase' AS SignalType,
                    b.Id AS BookId,
                    b.AuthorId,
                    bg.GenreId,
                    CAST(4.5 AS float) AS Weight
                FROM Users u
                INNER JOIN UserBooks ub ON ub.UserEmail = u.UserEmail
                INNER JOIN Books b ON b.Id = ub.BookId
                LEFT JOIN BookGenres bg ON bg.BookId = b.Id
                WHERE u.Id = @UserId
            ),
            ReviewSignals AS (
                SELECT
                    'review' AS SignalType,
                    b.Id AS BookId,
                    b.AuthorId,
                    bg.GenreId,
                    CAST(
                        CASE
                            WHEN r.Rating >= 4 THEN (r.Rating - 3) * 2.75
                            WHEN r.Rating = 3 THEN 0.75
                            ELSE (r.Rating - 3) * 2.50
                        END
                        AS float
                    ) AS Weight
                FROM Reviews r
                INNER JOIN Books b ON b.Id = r.BookId
                LEFT JOIN BookGenres bg ON bg.BookId = b.Id
                WHERE r.UserId = @UserId
            ),
            WishlistSignals AS (
                SELECT
                    'wishlist' AS SignalType,
                    b.Id AS BookId,
                    b.AuthorId,
                    bg.GenreId,
                    CAST(2.5 AS float) AS Weight
                FROM Wishlists w
                INNER JOIN WishlistItems wi ON wi.WishlistId = w.Id
                INNER JOIN Books b ON b.Id = wi.BookId
                LEFT JOIN BookGenres bg ON bg.BookId = b.Id
                WHERE w.UserId = @UserId
            ),
            CartSignals AS (
                SELECT
                    'cart' AS SignalType,
                    b.Id AS BookId,
                    b.AuthorId,
                    bg.GenreId,
                    CAST(3.0 AS float) AS Weight
                FROM ShoppingCarts sc
                INNER JOIN ShoppingCartItems sci ON sci.CartId = sc.Id
                INNER JOIN Books b ON b.Id = sci.BookId
                LEFT JOIN BookGenres bg ON bg.BookId = b.Id
                WHERE sc.UserId = @UserId
            )
            SELECT SignalType, BookId, AuthorId, GenreId, Weight FROM PurchaseSignals
            UNION ALL
            SELECT SignalType, BookId, AuthorId, GenreId, Weight FROM ReviewSignals
            UNION ALL
            SELECT SignalType, BookId, AuthorId, GenreId, Weight FROM WishlistSignals
            UNION ALL
            SELECT SignalType, BookId, AuthorId, GenreId, Weight FROM CartSignals;
            """;

        private const string CandidateBooksSql = """
            WITH ExcludedBooks AS (
                SELECT ub.BookId
                FROM Users u
                INNER JOIN UserBooks ub ON ub.UserEmail = u.UserEmail
                WHERE u.Id = @UserId
                UNION
                SELECT r.BookId
                FROM Reviews r
                WHERE r.UserId = @UserId
                UNION
                SELECT wi.BookId
                FROM Wishlists w
                INNER JOIN WishlistItems wi ON wi.WishlistId = w.Id
                WHERE w.UserId = @UserId
                UNION
                SELECT sci.BookId
                FROM ShoppingCarts sc
                INNER JOIN ShoppingCartItems sci ON sci.CartId = sc.Id
                WHERE sc.UserId = @UserId
            ),
            ReviewStats AS (
                SELECT
                    r.BookId,
                    CAST(AVG(CAST(r.Rating AS float)) AS float) AS AverageRating,
                    COUNT(*) AS ReviewCount
                FROM Reviews r
                GROUP BY r.BookId
            ),
            PurchaseStats AS (
                SELECT
                    ub.BookId,
                    COUNT(*) AS PurchaseCount
                FROM UserBooks ub
                GROUP BY ub.BookId
            ),
            WishlistStats AS (
                SELECT
                    wi.BookId,
                    COUNT(*) AS WishlistCount
                FROM WishlistItems wi
                GROUP BY wi.BookId
            ),
            CartStats AS (
                SELECT
                    sci.BookId,
                    COUNT(*) AS CartCount
                FROM ShoppingCartItems sci
                GROUP BY sci.BookId
            )
            SELECT TOP (@CandidatePoolSize)
                b.Id AS BookId,
                b.AuthorId,
                bg.GenreId,
                COALESCE(rs.AverageRating, 0) AS AverageRating,
                COALESCE(rs.ReviewCount, 0) AS ReviewCount,
                COALESCE(ps.PurchaseCount, 0) AS PurchaseCount,
                COALESCE(ws.WishlistCount, 0) AS WishlistCount,
                COALESCE(cs.CartCount, 0) AS CartCount
            FROM Books b
            LEFT JOIN BookGenres bg ON bg.BookId = b.Id
            LEFT JOIN ReviewStats rs ON rs.BookId = b.Id
            LEFT JOIN PurchaseStats ps ON ps.BookId = b.Id
            LEFT JOIN WishlistStats ws ON ws.BookId = b.Id
            LEFT JOIN CartStats cs ON cs.BookId = b.Id
            WHERE NOT EXISTS (
                SELECT 1
                FROM ExcludedBooks excluded
                WHERE excluded.BookId = b.Id
            )
            ORDER BY
                COALESCE(rs.AverageRating, 0) DESC,
                COALESCE(ps.PurchaseCount, 0) DESC,
                COALESCE(ws.WishlistCount, 0) DESC,
                COALESCE(cs.CartCount, 0) DESC,
                b.Title ASC;
            """;
    }
}
