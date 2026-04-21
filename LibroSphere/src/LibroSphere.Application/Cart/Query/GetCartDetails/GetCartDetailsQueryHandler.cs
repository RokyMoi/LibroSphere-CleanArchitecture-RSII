using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Cart.Query.GetCartDetails;

internal sealed class GetCartDetailsQueryHandler : IQueryHandler<GetCartDetailsQuery, CartDetailsResponse>
{
    private readonly IBookAssetStorageService _bookAssetStorageService;
    private readonly IBookRepository _bookRepository;
    private readonly ICartService _cartService;

    public GetCartDetailsQueryHandler(
        ICartService cartService,
        IBookRepository bookRepository,
        IBookAssetStorageService bookAssetStorageService)
    {
        _cartService = cartService;
        _bookRepository = bookRepository;
        _bookAssetStorageService = bookAssetStorageService;
    }

    public async Task<Result<CartDetailsResponse>> Handle(GetCartDetailsQuery request, CancellationToken cancellationToken)
    {
        var cart = await _cartService.GetCartASync(request.CartId.ToString());
        if (cart is null)
        {
            return Result.Failure<CartDetailsResponse>(Error.NullValue);
        }

        var bookIds = cart.Items
            .Select(item => item.BookId)
            .Distinct()
            .ToList();

        var books = await _bookRepository.GetByIdsWithDetailsAsync(bookIds, cancellationToken);
        var bookLookup = new Dictionary<Guid, BookResponse>(books.Count);

        foreach (var book in books)
        {
            var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
            var pdfLink = await _bookAssetStorageService.GetPdfReadUrlAsync(book.BookLinkovi.PdfLink, cancellationToken);
            var reviewCount = book.Reviews.Count;
            var averageRating = reviewCount == 0
                ? 0
                : book.Reviews.Average(review => review.Rating);

            bookLookup[book.Id] = new BookResponse
            {
                bookId = book.Id,
                Title = book.Title.Value,
                Description = book.Description.Value,
                amount = book.Price.amount,
                currency = book.Price.Currency.Code,
                pdfLink = pdfLink,
                imageLink = imageLink,
                AverageRating = averageRating,
                ReviewCount = reviewCount,
                AuthorId = book.AuthorId,
                AuthorName = book.Author?.Name.Value ?? string.Empty,
                GenreIds = book.BookGenres.Select(bg => bg.GenreId).ToList(),
                GenreNames = book.BookGenres
                    .Where(bg => bg.Genre is not null)
                    .Select(bg => bg.Genre!.Name.Value)
                    .OrderBy(name => name)
                    .ToList()
            };
        }

        var orderedBooks = cart.Items
            .Select(item => item.BookId)
            .Distinct()
            .Where(bookLookup.ContainsKey)
            .Select(bookId => bookLookup[bookId])
            .ToList();

        var items = cart.Items
            .Select(item => new CartDetailsItemResponse(
                item.BookId,
                new CartDetailsPriceResponse(
                    item.Price.amount,
                    item.Price.Currency.Code)))
            .ToList();

        return Result.Success(new CartDetailsResponse(
            cart.Id,
            cart.UserId,
            cart.ClientSecret,
            cart.PaymentIntentId,
            items,
            orderedBooks));
    }
}
