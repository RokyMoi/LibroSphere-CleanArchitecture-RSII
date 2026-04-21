using LibroSphere.Application.Events.Users;
using LibroSphere.Domain.Entities.Users.Events;
using MassTransit;
using MediatR;
using Microsoft.Extensions.Logging;

namespace LibroSphere.Application.Users.EventHandlers;

internal sealed class UserLoggedInDomainEventHandler : INotificationHandler<UserLoggedInDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<UserLoggedInDomainEventHandler> _logger;

    public UserLoggedInDomainEventHandler(
        IPublishEndpoint publishEndpoint,
        ILogger<UserLoggedInDomainEventHandler> logger)
    {
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task Handle(UserLoggedInDomainEvent notification, CancellationToken cancellationToken)
    {
        try
        {
            await _publishEndpoint.Publish(
                new UserLoggedInIntegrationEvent(notification.UserId, notification.Email),
                CancellationToken.None);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "User login integration event publish failed for {UserId}. Sign-in will continue without analytics event.",
                notification.UserId);
        }
    }
}

internal sealed class UserDeactivatedDomainEventHandler : INotificationHandler<UserDeactivatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<UserDeactivatedDomainEventHandler> _logger;

    public UserDeactivatedDomainEventHandler(
        IPublishEndpoint publishEndpoint,
        ILogger<UserDeactivatedDomainEventHandler> logger)
    {
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task Handle(UserDeactivatedDomainEvent notification, CancellationToken cancellationToken)
    {
        try
        {
            await _publishEndpoint.Publish(
                new UserDeactivatedIntegrationEvent(notification.UserId, notification.Email),
                CancellationToken.None);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "User deactivation integration event publish failed for {UserId}. Deactivation will continue without analytics event.",
                notification.UserId);
        }
    }
}
