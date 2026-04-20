using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.Common.Models;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;

namespace LibroSphere.Application.Library.Query.GetMyLibrary
{
    internal sealed class GetMyLibraryQueryHandler : IQueryHandler<GetMyLibraryQuery, PagedResponse<LibraryBookResponse>>
    {
        private readonly IUserBookRepository _userBookRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetMyLibraryQueryHandler(
            IUserBookRepository userBookRepository,
            IBookAssetStorageService bookAssetStorageService)
        {
            _userBookRepository = userBookRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<PagedResponse<LibraryBookResponse>>> Handle(GetMyLibraryQuery request, CancellationToken cancellationToken)
        {
            var userBooks = await _userBookRepository.GetByEmailAsync(request.Email);
            var filteredUserBooks = userBooks
                .Where(ub => string.IsNullOrWhiteSpace(request.SearchTerm) ||
                             ub.Book.Title.Value.Contains(request.SearchTerm, StringComparison.OrdinalIgnoreCase))
                .ToList();

            var response = new List<LibraryBookResponse>();
            foreach (var userBook in filteredUserBooks)
            {
                var imageLink = await _bookAssetStorageService.GetImageUrlAsync(
                    userBook.Book.BookLinkovi.imageLink,
                    cancellationToken);
                var reviewCount = userBook.Book.Reviews.Count;
                var averageRating = reviewCount == 0
                    ? 0
                    : userBook.Book.Reviews.Average(review => review.Rating);

                response.Add(new LibraryBookResponse(
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
                    userBook.PurchasedAt));
            }

            return Result.Success(PagedResponse<LibraryBookResponse>.Create(response, request.Page, request.PageSize));
        }
    }
}
