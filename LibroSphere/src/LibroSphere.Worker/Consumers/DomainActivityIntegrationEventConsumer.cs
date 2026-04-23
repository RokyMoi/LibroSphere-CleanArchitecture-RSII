using LibroSphere.Application.Abstractions.Analytics;
using LibroSphere.Application.Events.Authors;
using LibroSphere.Application.Events.Books;
using LibroSphere.Application.Events.Cart;
using LibroSphere.Application.Events.Genres;
using LibroSphere.Application.Events.Library;
using LibroSphere.Application.Events.Orders;
using LibroSphere.Application.Events.Reviews;
using LibroSphere.Application.Events.Users;
using LibroSphere.Application.Events.Wishlists;
using MassTransit;

namespace LibroSphere.Worker.Consumers;

public sealed class DomainActivityIntegrationEventConsumer :
    IConsumer<AuthorCreatedIntegrationEvent>,
    IConsumer<AuthorUpdatedIntegrationEvent>,
    IConsumer<AuthorDeletedIntegrationEvent>,
    IConsumer<BookCreatedIntegrationEvent>,
    IConsumer<BookUpdatedIntegrationEvent>,
    IConsumer<BookDeletedIntegrationEvent>,
    IConsumer<GenreCreatedIntegrationEvent>,
    IConsumer<GenreUpdatedIntegrationEvent>,
    IConsumer<GenreDeletedIntegrationEvent>,
    IConsumer<ReviewCreatedIntegrationEvent>,
    IConsumer<ReviewUpdatedIntegrationEvent>,
    IConsumer<ReviewDeletedIntegrationEvent>,
    IConsumer<WishlistCreatedIntegrationEvent>,
    IConsumer<WishlistItemAddedIntegrationEvent>,
    IConsumer<WishlistItemRemovedIntegrationEvent>,
    IConsumer<OrderCreatedIntegrationEvent>,
    IConsumer<OrderStatusChangedIntegrationEvent>,
    IConsumer<UserLoggedInIntegrationEvent>,
    IConsumer<UserDeactivatedIntegrationEvent>,
    IConsumer<CartUpdatedIntegrationEvent>,
    IConsumer<CartDeletedIntegrationEvent>,
    IConsumer<UserBookGrantedIntegrationEvent>
{
    private readonly IAnalyticsActivityStore _activityStore;
    private readonly ILogger<DomainActivityIntegrationEventConsumer> _logger;

    public DomainActivityIntegrationEventConsumer(
        IAnalyticsActivityStore activityStore,
        ILogger<DomainActivityIntegrationEventConsumer> logger)
    {
        _activityStore = activityStore;
        _logger = logger;
    }

    public Task Consume(ConsumeContext<AuthorCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Author",
            "Created",
            $"Author \"{context.Message.Name}\" was added to the catalog. ID: {context.Message.AuthorId}.{AdminSuffix(context.Message.AdminEmail)}",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<AuthorUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Author",
            "Updated",
            $"Author \"{context.Message.Name}\" was updated. ID: {context.Message.AuthorId}.{AdminSuffix(context.Message.AdminEmail)}",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<AuthorDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Author",
            "Deleted",
            $"Author \"{context.Message.Name}\" was deleted. ID: {context.Message.AuthorId}.{AdminSuffix(context.Message.AdminEmail)}",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<BookCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Book",
            "Created",
            $"Book \"{context.Message.Title}\" was added. Price: {FormatMoney(context.Message.Amount, context.Message.Currency)}. Book ID: {context.Message.BookId}. Author ID: {context.Message.AuthorId}.{AdminSuffix(context.Message.AdminEmail)}",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<BookUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Book",
            "Updated",
            $"Book \"{context.Message.Title}\" was updated. Price: {FormatMoney(context.Message.Amount, context.Message.Currency)}. Book ID: {context.Message.BookId}. Author ID: {context.Message.AuthorId}.{AdminSuffix(context.Message.AdminEmail)}",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<BookDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Book",
            "Deleted",
            $"Book \"{context.Message.Title}\" was deleted from the catalog. Book ID: {context.Message.BookId}. Author ID: {context.Message.AuthorId}.{AdminSuffix(context.Message.AdminEmail)}",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<GenreCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Genre",
            "Created",
            $"Genre \"{context.Message.Name}\" was created. Genre ID: {context.Message.GenreId}.{AdminSuffix(context.Message.AdminEmail)}",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<GenreUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Genre",
            "Updated",
            $"Genre \"{context.Message.Name}\" was updated. Genre ID: {context.Message.GenreId}.{AdminSuffix(context.Message.AdminEmail)}",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<GenreDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Genre",
            "Deleted",
            $"Genre \"{context.Message.Name}\" was deleted. Genre ID: {context.Message.GenreId}.{AdminSuffix(context.Message.AdminEmail)}",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<ReviewCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Review",
            "Created",
            $"A new review was added. Rating: {context.Message.Rating}/5. Review ID: {context.Message.ReviewId}. Book ID: {context.Message.BookId}. User ID: {context.Message.UserId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<ReviewUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Review",
            "Updated",
            $"The review was updated. New rating: {context.Message.Rating}/5. Review ID: {context.Message.ReviewId}. Book ID: {context.Message.BookId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<ReviewDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Review",
            "Deleted",
            $"The review was deleted. Review ID: {context.Message.ReviewId}. Book ID: {context.Message.BookId}. User ID: {context.Message.UserId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<WishlistCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Wishlist",
            "Created",
            $"The wishlist was created. Wishlist ID: {context.Message.WishlistId}. User ID: {context.Message.UserId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<WishlistItemAddedIntegrationEvent> context) =>
        RecordAsync(
            "Wishlist",
            "ItemAdded",
            $"A book was added to the wishlist. Wishlist ID: {context.Message.WishlistId}. Book ID: {context.Message.BookId}. User ID: {context.Message.UserId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<WishlistItemRemovedIntegrationEvent> context) =>
        RecordAsync(
            "Wishlist",
            "ItemRemoved",
            $"A book was removed from the wishlist. Wishlist ID: {context.Message.WishlistId}. Book ID: {context.Message.BookId}. User ID: {context.Message.UserId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<OrderCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Order",
            "Created",
            $"The order was created for {context.Message.BuyerEmail}. Amount: {FormatMoney(context.Message.TotalAmount, context.Message.Currency)}. Items: {context.Message.ItemCount}. Order ID: {context.Message.OrderId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<OrderStatusChangedIntegrationEvent> context) =>
        RecordAsync(
            "Order",
            "StatusChanged",
            $"The order {context.Message.OrderId} for {context.Message.BuyerEmail} changed to status \"{context.Message.Status}\".",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<UserLoggedInIntegrationEvent> context) =>
        RecordAsync(
            "User",
            "LoggedIn",
            $"User {context.Message.Email} logged in. User ID: {context.Message.UserId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<UserDeactivatedIntegrationEvent> context) =>
        RecordAsync(
            "User",
            "Deactivated",
            $"User {context.Message.Email} was deactivated. User ID: {context.Message.UserId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<CartUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Cart",
            "Updated",
            $"The cart was updated. Items: {context.Message.ItemCount}. Total: {FormatMoney(context.Message.TotalAmount, context.Message.Currency)}. Cart ID: {context.Message.CartId}. User ID: {context.Message.UserId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<CartDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Cart",
            "Deleted",
            $"The cart was deleted. Cart ID: {context.Message.CartId}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<UserBookGrantedIntegrationEvent> context) =>
        RecordAsync(
            "Library",
            "Granted",
            $"The purchase was moved to the library for {context.Message.UserEmail}. UserBook ID: {context.Message.UserBookId}. Book ID: {context.Message.BookId}.",
            context.Message.OccurredOnUtc);

    private async Task RecordAsync(string entityName, string action, string description, DateTime occurredOnUtc)
    {
        await _activityStore.AddAsync(new AnalyticsActivityEntry(entityName, action, description, occurredOnUtc));
        _logger.LogInformation("Activity projected. Entity={EntityName}, Action={Action}", entityName, action);
    }

    private static string AdminSuffix(string? adminEmail)
    {
        return string.IsNullOrWhiteSpace(adminEmail)
            ? string.Empty
            : $" Admin: {adminEmail}";
    }

    private static string FormatMoney(decimal amount, string currency)
    {
        return $"{amount:0.00} {currency}".Trim();
    }
}
