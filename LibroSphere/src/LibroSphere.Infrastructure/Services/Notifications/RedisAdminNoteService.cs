using System.Globalization;
using LibroSphere.Application.Abstractions.Notifications;
using StackExchange.Redis;

namespace LibroSphere.Infrastructure.Services.Notifications;

internal sealed class RedisAdminNoteService : IAdminNoteService
{
    private const string AdminNotesIndexKey = "admin-notes:index";
    private const string LegacyNewsIndexKey = "news:index";
    private readonly IDatabase _database;

    public RedisAdminNoteService(IConnectionMultiplexer connectionMultiplexer)
    {
        _database = connectionMultiplexer.GetDatabase();
    }

    public async Task<IReadOnlyCollection<AdminNoteDto>> GetLatestAsync(int take = 20, CancellationToken cancellationToken = default)
    {
        var ids = (await Task.WhenAll(
                _database.SortedSetRangeByRankAsync(AdminNotesIndexKey, 0, Math.Max(0, take - 1), Order.Descending),
                _database.SortedSetRangeByRankAsync(LegacyNewsIndexKey, 0, Math.Max(0, take - 1), Order.Descending)))
            .SelectMany(x => x)
            .Where(x => !x.IsNullOrEmpty)
            .Distinct()
            .ToArray();

        if (ids.Length == 0)
        {
            return Array.Empty<AdminNoteDto>();
        }

        var tasks = ids
            .Select(id => GetAdminNoteAsync(id.ToString()!))
            .ToArray();

        var items = await Task.WhenAll(tasks);
        return items
            .Where(x => x is not null)
            .Cast<AdminNoteDto>()
            .OrderByDescending(x => x.CreatedOnUtc)
            .ToList();
    }

    public async Task<AdminNoteDto> CreateAsync(string title, string text, string imageUrl, CancellationToken cancellationToken = default)
    {
        var id = Guid.NewGuid().ToString("N");
        var createdOnUtc = DateTime.UtcNow;
        var hashKey = BuildAdminNoteKey(id);

        var entries = new HashEntry[]
        {
            new("id", id),
            new("title", title),
            new("text", text),
            new("imageUrl", imageUrl),
            new("createdOnUtc", createdOnUtc.ToString("O", CultureInfo.InvariantCulture))
        };

        await _database.HashSetAsync(hashKey, entries);
        await _database.SortedSetAddAsync(AdminNotesIndexKey, id, new DateTimeOffset(createdOnUtc).ToUnixTimeSeconds());

        return new AdminNoteDto(id, title, text, imageUrl, createdOnUtc);
    }

    public async Task<bool> DeleteAsync(string id, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(id))
        {
            return false;
        }

        var normalizedId = id.Trim();
        var removedHash = await _database.KeyDeleteAsync(new RedisKey[]
        {
            BuildAdminNoteKey(normalizedId),
            BuildLegacyNewsKey(normalizedId)
        });
        await _database.SortedSetRemoveAsync(AdminNotesIndexKey, normalizedId);
        await _database.SortedSetRemoveAsync(LegacyNewsIndexKey, normalizedId);
        return removedHash > 0;
    }

    private async Task<AdminNoteDto?> GetAdminNoteAsync(string id)
    {
        var key = await _database.KeyExistsAsync(BuildAdminNoteKey(id))
            ? BuildAdminNoteKey(id)
            : BuildLegacyNewsKey(id);

        var values = await _database.HashGetAsync(
            key,
            new RedisValue[] { "id", "title", "text", "imageUrl", "createdOnUtc" });

        if (values.Length != 5 || values[0].IsNullOrEmpty)
        {
            return null;
        }

        var createdOnUtc = DateTime.TryParse(values[4].ToString(), null, DateTimeStyles.RoundtripKind, out var parsed)
            ? parsed
            : DateTime.UtcNow;

        return new AdminNoteDto(
            values[0].ToString() ?? id,
            values[1].ToString() ?? string.Empty,
            values[2].ToString() ?? string.Empty,
            values[3].ToString() ?? string.Empty,
            createdOnUtc);
    }

    private static string BuildAdminNoteKey(string id) => $"admin-notes:item:{id}";

    private static string BuildLegacyNewsKey(string id) => $"news:item:{id}";
}
