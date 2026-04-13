using LibroSphere.Application.Abstractions.Analytics;
using LibroSphere.Application.Events.User;
using LibroSphere.Domain.Entities.ShopCart;
using LibroSphere.Domain.Entities.WishList;
using LibroSphere.Infrastructure;
using LibroSphere.Worker.Services;
using MassTransit;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Worker.Consumers;

public sealed class UserRegisteredIntegrationEventConsumer : IConsumer<UserRegisteredIntegrationEvent>
{
    private readonly ApplicationDbContext? _dbContext;
    private readonly IEmailService _emailService;
    private readonly IAnalyticsActivityStore _activityStore;
    private readonly ILogger<UserRegisteredIntegrationEventConsumer> _logger;

    public UserRegisteredIntegrationEventConsumer(
        ApplicationDbContext? dbContext,
        IEmailService emailService,
        IAnalyticsActivityStore activityStore,
        ILogger<UserRegisteredIntegrationEventConsumer> logger)
    {
        _dbContext = dbContext;
        _emailService = emailService;
        _activityStore = activityStore;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<UserRegisteredIntegrationEvent> context)
    {
        var message = context.Message;

        _logger.LogInformation(
            "Processing user registration event. UserId={UserId}, Email={Email}",
            message.UserId,
            message.Email);

        await _activityStore.AddAsync(
            new AnalyticsActivityEntry(
                "User",
                "Registered",
                $"Korisnik {message.Email} se registrovao i pokrenut je onboarding.",
                DateTime.UtcNow),
            context.CancellationToken);

        if (_dbContext is not null)
        {
            var hasCart = await _dbContext.Set<ShoppingCart>()
                .AnyAsync(x => x.UserId == message.UserId, context.CancellationToken);

            if (!hasCart)
            {
                await _dbContext.Set<ShoppingCart>()
                    .AddAsync(ShoppingCart.CreateCart(message.UserId), context.CancellationToken);
            }

            var hasWishlist = await _dbContext.Set<Wishlist>()
                .AnyAsync(x => x.UserId == message.UserId, context.CancellationToken);

            if (!hasWishlist)
            {
                await _dbContext.Set<Wishlist>()
                    .AddAsync(Wishlist.CreateWishlist(message.UserId), context.CancellationToken);
            }

            await _dbContext.SaveChangesAsync(context.CancellationToken);
        }
        else
        {
            _logger.LogWarning(
                "Worker has no ApplicationDbContext configured. Skipping cart and wishlist bootstrap for {UserId}",
                message.UserId);
        }

        var body = $"""
                    <h2>Dobrodosli u LibroSphere</h2>
                    <p>Zdravo {message.FirstName} {message.LastName},</p>
                    <p>uspjesno ste registrovani.</p>
                    <p><strong>Tvoj email:</strong> {message.Email}</p>
                    <p><strong>Tvoja lozinka:</strong> {message.Password}</p>
                    """;

        try
        {
            await _emailService.SendAsync(
                message.Email,
                "Dobrodosli u LibroSphere",
                body,
                context.CancellationToken);

            _logger.LogInformation(
                "Welcome email handled. UserId={UserId}, Email={Email}",
                message.UserId,
                message.Email);
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Welcome email delivery failed. UserId={UserId}, Email={Email}",
                message.UserId,
                message.Email);
        }
    }
}
