using LibroSphere.Application.Books.Query.GetBookByIdQuery;

namespace LibroSphere.Application.Cart.Query.GetCartDetails;

public sealed record CartDetailsResponse(
    Guid Id,
    Guid UserId,
    string? ClientSecret,
    string? PaymentIntentId,
    IReadOnlyList<CartDetailsItemResponse> Items,
    IReadOnlyList<BookResponse> Books);

public sealed record CartDetailsItemResponse(
    Guid BookId,
    CartDetailsPriceResponse Price);

public sealed record CartDetailsPriceResponse(
    decimal Amount,
    string CurrencyCode);
