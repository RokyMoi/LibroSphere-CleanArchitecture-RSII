using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using LibroSphere.Application.Abstractions.Analytics;
using LibroSphere.Application.Abstractions.Notifications;
using StackExchange.Redis;

namespace LibroSphere.Infrastructure.Services.Notifications;

internal sealed class RedisNotificationCenterService : INotificationCenterService
{
    private readonly IAnalyticsActivityStore _activityStore;
    private readonly IDatabase _database;
    private static readonly Regex LabeledIdRegex = new(
        @"\s*(?:[A-Za-z]+(?:\s+[A-Za-z]+)*)\s+ID:\s*[^.]+\.?",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);
    private static readonly Regex GuidRegex = new(
        @"\b[0-9A-F]{8}(?:-[0-9A-F]{4}){3}-[0-9A-F]{12}\b",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);
    private static readonly Regex ShortHexIdRegex = new(
        @"\b[0-9A-F]{8}\b",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);
    private static readonly Regex PunctuationSpacingRegex = new(
        @"\s+([,.;:])",
        RegexOptions.Compiled);
    private static readonly Regex DuplicatePeriodRegex = new(
        @"(?:\.\s*){2,}",
        RegexOptions.Compiled);
    private static readonly Regex WhitespaceRegex = new(
        @"\s+",
        RegexOptions.Compiled);

    private static readonly HashSet<string> UserRelevantEntities = new(StringComparer.OrdinalIgnoreCase)
    {
        "Wishlist",
        "Cart",
        "Order",
        "Library"
    };

    public RedisNotificationCenterService(
        IAnalyticsActivityStore activityStore,
        IConnectionMultiplexer connectionMultiplexer)
    {
        _activityStore = activityStore;
        _database = connectionMultiplexer.GetDatabase();
    }

    public async Task<IReadOnlyCollection<SystemNotificationDto>> GetNotificationsAsync(
        Guid userId,
        string? userEmail,
        int take = 20,
        CancellationToken cancellationToken = default)
    {
        var activities = await _activityStore.GetRecentAsync(Math.Clamp(take * 3, 1, 300), cancellationToken);
        var readKey = BuildReadKey(userId);
        var readIds = (await _database.SetMembersAsync(readKey))
            .Select(x => x.ToString())
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var notifications = activities
            .Where(activity => IsRelevantToUser(activity, userId, userEmail))
            .Select(activity =>
            {
                var id = BuildNotificationId(activity);
                var (title, text) = FormatNotification(activity);
                return new SystemNotificationDto(
                    id,
                    readIds.Contains(id),
                    title,
                    text,
                    activity.OccurredOnUtc);
            })
            .OrderByDescending(x => x.OccurredOnUtc)
            .Take(take)
            .ToList();

        return notifications;
    }

    private static bool IsRelevantToUser(AnalyticsActivityEntry activity, Guid userId, string? userEmail)
    {
        if (!UserRelevantEntities.Contains(activity.EntityName))
        {
            return false;
        }

        var userIdShort = userId.ToString("N")[..8].ToUpperInvariant();
        if (activity.Description.Contains(userIdShort, StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        return !string.IsNullOrWhiteSpace(userEmail) &&
               activity.Description.Contains(userEmail, StringComparison.OrdinalIgnoreCase);
    }

    private static (string Title, string Text) FormatNotification(AnalyticsActivityEntry activity)
    {
        var title = $"{activity.EntityName} - {activity.Action}";
        var text = CleanDescription(activity.Description);
        return (title, text);
    }

    private static string CleanDescription(string description)
    {
        var cleaned = LabeledIdRegex.Replace(description, string.Empty);
        cleaned = GuidRegex.Replace(cleaned, string.Empty);
        cleaned = ShortHexIdRegex.Replace(cleaned, string.Empty);
        cleaned = PunctuationSpacingRegex.Replace(cleaned, "$1");
        cleaned = DuplicatePeriodRegex.Replace(cleaned, ". ");
        cleaned = WhitespaceRegex.Replace(cleaned, " ").Trim();
        cleaned = cleaned.Trim(' ', '.', ',', ';', ':');

        return string.IsNullOrWhiteSpace(cleaned)
            ? "You have a new notification."
            : $"{cleaned}.";
    }

    public async Task MarkAsReadAsync(Guid userId, string notificationId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(notificationId))
        {
            return;
        }

        await _database.SetAddAsync(BuildReadKey(userId), notificationId.Trim());
    }

    public async Task MarkAllAsReadAsync(Guid userId, string? userEmail, int take = 100, CancellationToken cancellationToken = default)
    {
        var activities = await _activityStore.GetRecentAsync(Math.Clamp(take * 3, 1, 300), cancellationToken);
        var ids = activities
            .Where(activity => IsRelevantToUser(activity, userId, userEmail))
            .Select(BuildNotificationId)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Select(x => (RedisValue)x)
            .ToArray();

        if (ids.Length == 0)
        {
            return;
        }

        await _database.SetAddAsync(BuildReadKey(userId), ids);
    }

    private static string BuildReadKey(Guid userId) => $"notifications:read:{userId:D}";

    private static string BuildNotificationId(AnalyticsActivityEntry entry)
    {
        var payload = $"{entry.EntityName}|{entry.Action}|{entry.Description}|{entry.OccurredOnUtc:O}";
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(payload));
        return Convert.ToHexString(hash);
    }
}
