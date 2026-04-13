using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Cart.Command.DeleteCart
{
    public sealed record DeleteCartCommand(Guid CartId) : ICommand;
}
