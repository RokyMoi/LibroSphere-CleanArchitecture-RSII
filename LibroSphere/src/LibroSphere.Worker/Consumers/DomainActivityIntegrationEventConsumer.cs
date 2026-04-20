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
            $"Autor \"{context.Message.Name}\" je dodan u katalog. ID: {ShortId(context.Message.AuthorId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<AuthorUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Author",
            "Updated",
            $"Autor \"{context.Message.Name}\" je azuriran. ID: {ShortId(context.Message.AuthorId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<AuthorDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Author",
            "Deleted",
            $"Autor \"{context.Message.Name}\" je obrisan. ID: {ShortId(context.Message.AuthorId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<BookCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Book",
            "Created",
            $"Knjiga \"{context.Message.Title}\" je dodana. Cijena: {FormatMoney(context.Message.Amount, context.Message.Currency)}. Book ID: {ShortId(context.Message.BookId)}. Author ID: {ShortId(context.Message.AuthorId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<BookUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Book",
            "Updated",
            $"Knjiga \"{context.Message.Title}\" je azurirana. Cijena: {FormatMoney(context.Message.Amount, context.Message.Currency)}. Book ID: {ShortId(context.Message.BookId)}. Author ID: {ShortId(context.Message.AuthorId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<BookDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Book",
            "Deleted",
            $"Knjiga \"{context.Message.Title}\" je obrisana iz kataloga. Book ID: {ShortId(context.Message.BookId)}. Author ID: {ShortId(context.Message.AuthorId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<GenreCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Genre",
            "Created",
            $"Zanr \"{context.Message.Name}\" je kreiran. Genre ID: {ShortId(context.Message.GenreId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<GenreUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Genre",
            "Updated",
            $"Zanr \"{context.Message.Name}\" je azuriran. Genre ID: {ShortId(context.Message.GenreId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<GenreDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Genre",
            "Deleted",
            $"Zanr \"{context.Message.Name}\" je obrisan. Genre ID: {ShortId(context.Message.GenreId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<ReviewCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Review",
            "Created",
            $"Nova recenzija je dodana. Ocjena: {context.Message.Rating}/5. Review ID: {ShortId(context.Message.ReviewId)}. Book ID: {ShortId(context.Message.BookId)}. User ID: {ShortId(context.Message.UserId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<ReviewUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Review",
            "Updated",
            $"Recenzija je azurirana. Nova ocjena: {context.Message.Rating}/5. Review ID: {ShortId(context.Message.ReviewId)}. Book ID: {ShortId(context.Message.BookId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<ReviewDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Review",
            "Deleted",
            $"Recenzija je obrisana. Review ID: {ShortId(context.Message.ReviewId)}. Book ID: {ShortId(context.Message.BookId)}. User ID: {ShortId(context.Message.UserId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<WishlistCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Wishlist",
            "Created",
            $"Wishlist je kreirana. Wishlist ID: {ShortId(context.Message.WishlistId)}. User ID: {ShortId(context.Message.UserId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<WishlistItemAddedIntegrationEvent> context) =>
        RecordAsync(
            "Wishlist",
            "ItemAdded",
            $"Knjiga je dodana u wishlist. Wishlist ID: {ShortId(context.Message.WishlistId)}. Book ID: {ShortId(context.Message.BookId)}. User ID: {ShortId(context.Message.UserId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<WishlistItemRemovedIntegrationEvent> context) =>
        RecordAsync(
            "Wishlist",
            "ItemRemoved",
            $"Knjiga je uklonjena iz wishlist-e. Wishlist ID: {ShortId(context.Message.WishlistId)}. Book ID: {ShortId(context.Message.BookId)}. User ID: {ShortId(context.Message.UserId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<OrderCreatedIntegrationEvent> context) =>
        RecordAsync(
            "Order",
            "Created",
            $"Narudzba je kreirana za {context.Message.BuyerEmail}. Iznos: {FormatMoney(context.Message.TotalAmount, context.Message.Currency)}. Stavki: {context.Message.ItemCount}. Order ID: {ShortId(context.Message.OrderId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<OrderStatusChangedIntegrationEvent> context) =>
        RecordAsync(
            "Order",
            "StatusChanged",
            $"Narudzba {ShortId(context.Message.OrderId)} za {context.Message.BuyerEmail} je presla u status \"{context.Message.Status}\".",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<UserLoggedInIntegrationEvent> context) =>
        RecordAsync(
            "User",
            "LoggedIn",
            $"Korisnik {context.Message.Email} se prijavio. User ID: {ShortId(context.Message.UserId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<UserDeactivatedIntegrationEvent> context) =>
        RecordAsync(
            "User",
            "Deactivated",
            $"Korisnik {context.Message.Email} je deaktiviran. User ID: {ShortId(context.Message.UserId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<CartUpdatedIntegrationEvent> context) =>
        RecordAsync(
            "Cart",
            "Updated",
            $"Korpa je azurirana. Stavki: {context.Message.ItemCount}. Ukupno: {FormatMoney(context.Message.TotalAmount, context.Message.Currency)}. Cart ID: {ShortId(context.Message.CartId)}. User ID: {ShortId(context.Message.UserId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<CartDeletedIntegrationEvent> context) =>
        RecordAsync(
            "Cart",
            "Deleted",
            $"Korpa je obrisana. Cart ID: {ShortId(context.Message.CartId)}.",
            context.Message.OccurredOnUtc);

    public Task Consume(ConsumeContext<UserBookGrantedIntegrationEvent> context) =>
        RecordAsync(
            "Library",
            "Granted",
            $"Kupovina je prebacena u biblioteku za {context.Message.UserEmail}. UserBook ID: {ShortId(context.Message.UserBookId)}. Book ID: {ShortId(context.Message.BookId)}.",
            context.Message.OccurredOnUtc);

    private async Task RecordAsync(string entityName, string action, string description, DateTime occurredOnUtc)
    {
        await _activityStore.AddAsync(new AnalyticsActivityEntry(entityName, action, description, occurredOnUtc));
        _logger.LogInformation("Activity projected. Entity={EntityName}, Action={Action}", entityName, action);
    }

    private static string ShortId(Guid value)
    {
        var text = value.ToString("N");
        return text.Length <= 8 ? text : text[..8].ToUpperInvariant();
    }

    private static string FormatMoney(decimal amount, string currency)
    {
        return $"{amount:0.00} {currency}".Trim();
    }
}
