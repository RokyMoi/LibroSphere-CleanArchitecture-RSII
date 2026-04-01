using LibroSphere.Application.Events.User;
using LibroSphere.Domain.Entities.Users;
using MassTransit;
using Microsoft.Extensions.Logging;

namespace LibroSphere.Worker.Consumers;

// MassTransit automatski registruje queue za ovaj consumer
internal sealed class UserCreatedIntegrationEventConsumer
    : IConsumer<UserCreatedIntegrationEvent>
{
    private readonly ILogger<UserCreatedIntegrationEventConsumer> _logger;

    public UserCreatedIntegrationEventConsumer(
        ILogger<UserCreatedIntegrationEventConsumer> logger)
    {
        _logger = logger;
    }

    public async Task Consume(
        ConsumeContext<UserCreatedIntegrationEvent> context)
    {
        _logger.LogInformation(
            "Worker Got: User was created. UserId={UserId}, Email={Email}",
            context.Message.UserId,
            context.Message.Email);

        

   

        await Task.CompletedTask;
    }
}