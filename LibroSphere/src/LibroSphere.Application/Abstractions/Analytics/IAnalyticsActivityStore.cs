namespace LibroSphere.Application.Abstractions.Analytics;

public interface IAnalyticsActivityStore
{
    Task AddAsync(AnalyticsActivityEntry entry, CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<AnalyticsActivityEntry>> GetRecentAsync(int take, CancellationToken cancellationToken = default);
}

public sealed class AnalyticsActivityEntry
{
    public AnalyticsActivityEntry()
    {
        EntityName = string.Empty;
        Action = string.Empty;
        Description = string.Empty;
    }

    public AnalyticsActivityEntry(string entityName, string action, string description, DateTime occurredOnUtc)
    {
        EntityName = entityName;
        Action = action;
        Description = description;
        OccurredOnUtc = occurredOnUtc;
    }

    public string EntityName { get; init; }
    public string Action { get; init; }
    public string Description { get; init; }
    public DateTime OccurredOnUtc { get; init; }
}
