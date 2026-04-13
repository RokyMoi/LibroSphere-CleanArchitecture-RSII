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

    public Task Consume(ConsumeContext<AuthorCreatedIntegrationEvent> context) => RecordAsync("Author", "Created", $"Author '{context.Message.Name}' je dodan u katalog.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<AuthorUpdatedIntegrationEvent> context) => RecordAsync("Author", "Updated", $"Author '{context.Message.Name}' je azuriran.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<AuthorDeletedIntegrationEvent> context) => RecordAsync("Author", "Deleted", $"Author '{context.Message.Name}' je obrisan.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<BookCreatedIntegrationEvent> context) => RecordAsync("Book", "Created", $"Book '{context.Message.Title}' je dodana sa cijenom {context.Message.Amount:0.00} {context.Message.Currency}.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<BookUpdatedIntegrationEvent> context) => RecordAsync("Book", "Updated", $"Book '{context.Message.Title}' je azurirana.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<BookDeletedIntegrationEvent> context) => RecordAsync("Book", "Deleted", $"Book '{context.Message.Title}' je obrisana iz kataloga.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<GenreCreatedIntegrationEvent> context) => RecordAsync("Genre", "Created", $"Genre '{context.Message.Name}' je kreiran.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<GenreUpdatedIntegrationEvent> context) => RecordAsync("Genre", "Updated", $"Genre '{context.Message.Name}' je azuriran.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<GenreDeletedIntegrationEvent> context) => RecordAsync("Genre", "Deleted", $"Genre '{context.Message.Name}' je obrisan.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<ReviewCreatedIntegrationEvent> context) => RecordAsync("Review", "Created", $"Nova recenzija sa ocjenom {context.Message.Rating} za knjigu {context.Message.BookId}.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<ReviewUpdatedIntegrationEvent> context) => RecordAsync("Review", "Updated", $"Recenzija {context.Message.ReviewId} je azurirana na ocjenu {context.Message.Rating}.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<ReviewDeletedIntegrationEvent> context) => RecordAsync("Review", "Deleted", $"Recenzija {context.Message.ReviewId} je obrisana.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<WishlistCreatedIntegrationEvent> context) => RecordAsync("Wishlist", "Created", $"Wishlist je kreirana za korisnika {context.Message.UserId}.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<WishlistItemAddedIntegrationEvent> context) => RecordAsync("Wishlist", "ItemAdded", $"Knjiga {context.Message.BookId} je dodana u wishlist korisnika {context.Message.UserId}.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<WishlistItemRemovedIntegrationEvent> context) => RecordAsync("Wishlist", "ItemRemoved", $"Knjiga {context.Message.BookId} je uklonjena iz wishlist-e korisnika {context.Message.UserId}.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<OrderCreatedIntegrationEvent> context) => RecordAsync("Order", "Created", $"Narudzba {context.Message.OrderId} je kreirana za {context.Message.BuyerEmail}.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<OrderStatusChangedIntegrationEvent> context) => RecordAsync("Order", "StatusChanged", $"Narudzba {context.Message.OrderId} je presla u status {context.Message.Status}.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<UserLoggedInIntegrationEvent> context) => RecordAsync("User", "LoggedIn", $"Korisnik {context.Message.Email} se prijavio.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<UserDeactivatedIntegrationEvent> context) => RecordAsync("User", "Deactivated", $"Korisnik {context.Message.Email} je deaktiviran.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<CartUpdatedIntegrationEvent> context) => RecordAsync("Cart", "Updated", $"Korpa {context.Message.CartId} sada ima {context.Message.ItemCount} stavki.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<CartDeletedIntegrationEvent> context) => RecordAsync("Cart", "Deleted", $"Korpa {context.Message.CartId} je obrisana.", context.Message.OccurredOnUtc);
    public Task Consume(ConsumeContext<UserBookGrantedIntegrationEvent> context) => RecordAsync("Library", "Granted", $"Korisnik {context.Message.UserEmail} je dobio pristup knjizi {context.Message.BookId}.", context.Message.OccurredOnUtc);

    private async Task RecordAsync(string entityName, string action, string description, DateTime occurredOnUtc)
    {
        await _activityStore.AddAsync(new AnalyticsActivityEntry(entityName, action, description, occurredOnUtc));
        _logger.LogInformation("Activity projected. Entity={EntityName}, Action={Action}", entityName, action);
    }
}
