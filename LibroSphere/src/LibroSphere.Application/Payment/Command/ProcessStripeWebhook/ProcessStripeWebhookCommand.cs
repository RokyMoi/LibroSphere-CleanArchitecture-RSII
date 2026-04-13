using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Payment.Command.ProcessStripeWebhook;

public sealed record ProcessStripeWebhookCommand(string Json, string Signature, string WebhookSecret) : ICommand;
