using System.Globalization;
using LibroSphere.Application.Abstractions.Notifications;
using StackExchange.Redis;

namespace LibroSphere.Infrastructure.Services.Notifications;

internal sealed class RedisNewsService : INewsService
{
    private const string NewsIndexKey = "news:index";
    private readonly IDatabase _database;

    public RedisNewsService(IConnectionMultiplexer connectionMultiplexer)
    {
        _database = connectionMultiplexer.GetDatabase();
    }

    public async Task<IReadOnlyCollection<NewsItemDto>> GetLatestAsync(int take = 20, CancellationToken cancellationToken = default)
    {
        var ids = await _database.SortedSetRangeByRankAsync(NewsIndexKey, 0, Math.Max(0, take - 1), Order.Descending);
        if (ids.Length == 0)
        {
            return Array.Empty<NewsItemDto>();
        }

        var tasks = ids
            .Where(x => !x.IsNullOrEmpty)
            .Select(id => GetNewsItemAsync(id.ToString()!))
            .ToArray();

        var items = await Task.WhenAll(tasks);
        return items
            .Where(x => x is not null)
            .Cast<NewsItemDto>()
            .OrderByDescending(x => x.CreatedOnUtc)
            .ToList();
    }

    public async Task<NewsItemDto> CreateAsync(string title, string text, string imageUrl, CancellationToken cancellationToken = default)
    {
        var id = Guid.NewGuid().ToString("N");
        var createdOnUtc = DateTime.UtcNow;
        var hashKey = BuildNewsItemKey(id);

        var entries = new HashEntry[]
        {
            new("id", id),
            new("title", title),
            new("text", text),
            new("imageUrl", imageUrl),
            new("createdOnUtc", createdOnUtc.ToString("O", CultureInfo.InvariantCulture))
        };

        await _database.HashSetAsync(hashKey, entries);
        await _database.SortedSetAddAsync(NewsIndexKey, id, new DateTimeOffset(createdOnUtc).ToUnixTimeSeconds());

        return new NewsItemDto(id, title, text, imageUrl, createdOnUtc);
    }

    public async Task<bool> DeleteAsync(string id, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(id))
        {
            return false;
        }

        var normalizedId = id.Trim();
        var removedHash = await _database.KeyDeleteAsync(BuildNewsItemKey(normalizedId));
        await _database.SortedSetRemoveAsync(NewsIndexKey, normalizedId);
        return removedHash;
    }

    private async Task<NewsItemDto?> GetNewsItemAsync(string id)
    {
        var values = await _database.HashGetAsync(
            BuildNewsItemKey(id),
            new RedisValue[] { "id", "title", "text", "imageUrl", "createdOnUtc" });

        if (values.Length != 5 || values[0].IsNullOrEmpty)
        {
            return null;
        }

        var createdOnUtc = DateTime.TryParse(values[4].ToString(), null, DateTimeStyles.RoundtripKind, out var parsed)
            ? parsed
            : DateTime.UtcNow;

        return new NewsItemDto(
            values[0].ToString() ?? id,
            values[1].ToString() ?? string.Empty,
            values[2].ToString() ?? string.Empty,
            values[3].ToString() ?? string.Empty,
            createdOnUtc);
    }

    private static string BuildNewsItemKey(string id) => $"news:item:{id}";
}
