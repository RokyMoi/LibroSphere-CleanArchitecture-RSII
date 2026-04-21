using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Cart.Query.GetCartDetails;

public sealed record GetCartDetailsQuery(Guid CartId) : IQuery<CartDetailsResponse>;
