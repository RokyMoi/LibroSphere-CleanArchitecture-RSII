using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Cart.Query.GetCartDetails;

internal sealed class GetCartDetailsQueryHandler : IQueryHandler<GetCartDetailsQuery, CartDetailsResponse>
{
    private readonly IBookAssetStorageService _bookAssetStorageService;
    private readonly IBookRepository _bookRepository;
    private readonly IReviewRepository _reviewRepository;
    private readonly ICartService _cartService;

    public GetCartDetailsQueryHandler(
        ICartService cartService,
        IBookRepository bookRepository,
        IReviewRepository reviewRepository,
        IBookAssetStorageService bookAssetStorageService)
    {
        _cartService = cartService;
        _bookRepository = bookRepository;
        _reviewRepository = reviewRepository;
        _bookAssetStorageService = bookAssetStorageService;
    }

    public async Task<Result<CartDetailsResponse>> Handle(GetCartDetailsQuery request, CancellationToken cancellationToken)
    {
        var cart = await _cartService.GetCartAsync(request.CartId.ToString());
        if (cart is null)
        {
            return Result.Failure<CartDetailsResponse>(Error.NullValue);
        }

        var bookIds = cart.Items
            .Select(item => item.BookId)
            .Distinct()
            .ToList();

        var books = await _bookRepository.GetByIdsWithDetailsAsync(bookIds, cancellationToken);
        var reviewStats = await _reviewRepository.GetStatsForBooksAsync(bookIds, cancellationToken);
        var bookResponses = await Task.WhenAll(books.Select(async book =>
        {
            var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
            var stats = reviewStats.TryGetValue(book.Id, out var s) ? s : new BookReviewStats(0, 0);

            return new BookResponse
            {
                bookId = book.Id,
                Title = book.Title.Value,
                Description = book.Description.Value,
                amount = book.Price.amount,
                currency = book.Price.Currency.Code,
                imageLink = imageLink,
                AverageRating = stats.Average,
                ReviewCount = stats.Count,
                AuthorId = book.AuthorId,
                AuthorName = book.Author?.Name.Value ?? string.Empty,
                GenreIds = book.BookGenres.Select(bg => bg.GenreId).ToList(),
                GenreNames = book.BookGenres
                    .Where(bg => bg.Genre is not null)
                    .Select(bg => bg.Genre!.Name.Value)
                    .OrderBy(name => name)
                    .ToList()
            };
        }));

        var bookLookup = bookResponses.ToDictionary(book => book.bookId);

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
