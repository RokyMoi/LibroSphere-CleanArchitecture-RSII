using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.Common.Models;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
using LibroSphere.Domain.Entities.Reviews;

namespace LibroSphere.Application.Library.Query.GetMyLibrary
{
    internal sealed class GetMyLibraryQueryHandler : IQueryHandler<GetMyLibraryQuery, PagedResponse<LibraryBookResponse>>
    {
        private readonly IUserBookRepository _userBookRepository;
        private readonly IReviewRepository _reviewRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetMyLibraryQueryHandler(
            IUserBookRepository userBookRepository,
            IReviewRepository reviewRepository,
            IBookAssetStorageService bookAssetStorageService)
        {
            _userBookRepository = userBookRepository;
            _reviewRepository = reviewRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<PagedResponse<LibraryBookResponse>>> Handle(GetMyLibraryQuery request, CancellationToken cancellationToken)
        {
            var page = Math.Max(1, request.Page);
            var pageSize = Math.Clamp(request.PageSize, 1, 100);

            var (pagedUserBooks, totalCount) = await _userBookRepository.GetPagedByUserIdAsync(
                request.UserId,
                request.SearchTerm,
                page,
                pageSize,
                cancellationToken);

            var bookIds = pagedUserBooks.Select(ub => ub.BookId).ToList();
            var reviewStats = await _reviewRepository.GetStatsForBooksAsync(bookIds, cancellationToken);

            var response = await Task.WhenAll(pagedUserBooks.Select(async userBook =>
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(
                    userBook.Book.BookLinkovi.imageLink,
                    cancellationToken);
                var stats = reviewStats.TryGetValue(userBook.BookId, out var s) ? s : new BookReviewStats(0, 0);
                var reviewCount = stats.Count;
                var averageRating = stats.Average;

                return new LibraryBookResponse(
                    userBook.BookId,
                    userBook.Book.Title.Value,
                    userBook.Book.Description.Value,
                    userBook.Book.Price.amount,
                    userBook.Book.Price.Currency.Code,
                    null,
                    imageLink,
                    averageRating,
                    reviewCount,
                    userBook.Book.AuthorId,
                    userBook.Book.Author?.Name.Value ?? string.Empty,
                    userBook.Book.BookGenres.Select(bg => bg.GenreId).ToList(),
                    userBook.Book.BookGenres
                        .Where(bg => bg.Genre is not null)
                        .Select(bg => bg.Genre!.Name.Value)
                        .OrderBy(name => name)
                        .ToList(),
                    userBook.PurchasedAt);
            }));

            return Result.Success(new PagedResponse<LibraryBookResponse>(response, page, pageSize, totalCount));
        }
    }
}
