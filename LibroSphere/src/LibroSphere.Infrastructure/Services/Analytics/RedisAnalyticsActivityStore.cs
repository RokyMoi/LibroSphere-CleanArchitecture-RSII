using System.Text.Json;
using LibroSphere.Application.Abstractions.Analytics;
using StackExchange.Redis;

namespace LibroSphere.Infrastructure.Services.Analytics;

public sealed class RedisAnalyticsActivityStore : IAnalyticsActivityStore
{
    private const string ActivityKey = "analytics:recent-activity";
    private const int MaxEntries = 100;
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly IDatabase _database;

    public RedisAnalyticsActivityStore(IConnectionMultiplexer connectionMultiplexer)
    {
        _database = connectionMultiplexer.GetDatabase();
    }

    public async Task AddAsync(AnalyticsActivityEntry entry, CancellationToken cancellationToken = default)
    {
        var payload = JsonSerializer.Serialize(entry, JsonOptions);
        await _database.ListLeftPushAsync(ActivityKey, payload);
        await _database.ListTrimAsync(ActivityKey, 0, MaxEntries - 1);
    }

    public async Task<IReadOnlyCollection<AnalyticsActivityEntry>> GetRecentAsync(int take, CancellationToken cancellationToken = default)
    {
        var values = await _database.ListRangeAsync(ActivityKey, 0, Math.Max(0, take - 1));
        return values
            .Where(x => !x.IsNullOrEmpty)
            .Select(x => JsonSerializer.Deserialize<AnalyticsActivityEntry>(x!, JsonOptions))
            .Where(x => x is not null)
            .Cast<AnalyticsActivityEntry>()
            .ToList();
    }
}
