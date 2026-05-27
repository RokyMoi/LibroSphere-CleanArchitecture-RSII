using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.Common.Models;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Domain.Entities.Books;

namespace LibroSphere.Application.Books.Query.GetAllBooks
{
    internal sealed class GetAllBooksQueryHandler : IQueryHandler<GetAllBooksQuery, PagedResponse<BookResponse>>
    {
        private readonly IBookRepository _bookRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetAllBooksQueryHandler(IBookRepository bookRepository, IBookAssetStorageService bookAssetStorageService)
        {
            _bookRepository = bookRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<PagedResponse<BookResponse>>> Handle(GetAllBooksQuery request, CancellationToken cancellationToken)
        {
            var page = Math.Max(1, request.Page);
            var pageSize = Math.Clamp(request.PageSize, 1, 100);

            var books = await _bookRepository.SearchAsync(
                request.SearchTerm,
                request.AuthorId,
                request.GenreId,
                request.MinPrice,
                request.MaxPrice,
                request.MinRating,
                cancellationToken);

            var totalCount = books.Count;
            var pageBooks = books
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            var response = await Task.WhenAll(pageBooks.Select(async book =>
            {
                var imageLinkTask = _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);
                await imageLinkTask;

                var reviewCount = book.Reviews.Count;
                var averageRating = reviewCount == 0
                    ? 0
                    : book.Reviews.Average(review => review.Rating);

                return new BookResponse
                {
                    bookId = book.Id,
                    Title = book.Title.Value,
                    Description = book.Description.Value,
                    amount = book.Price.amount,
                    currency = book.Price.Currency.Code,
                    imageLink = await imageLinkTask,
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
            }));

            return Result.Success(new PagedResponse<BookResponse>(
                response,
                page,
                pageSize,
                totalCount));
        }
    }
}
