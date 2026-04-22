using LibroSphere.Application.Books.Command.CreateNewBook;
using LibroSphere.Application.Books.Command.DeleteBook;
using LibroSphere.Application.Books.Command.UpdateBook;
using LibroSphere.Application.Authors.Query.GetAuthorById;
using LibroSphere.Application.Authors.Query.GetAllAuthors;
using LibroSphere.Application.Books.Query.GetAllBooks;
using LibroSphere.Application.Books.Query.GetBookAssetLinksById;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.Genres;
using LibroSphere.Application.Genres.Query.GetAllGenres;
using LibroSphere.Application.Recommendations.Query.GetRecommendedBooks;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Shared;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LibroSphere.WebApi.Extensions;

namespace LibroSphere.WebApi.Controllers.Book
{
    [Route("api/[controller]")]
    [ApiController]
    public class BookController : ControllerBase
    {
        private readonly ISender _sender;
        private readonly IBookAssetStorageService _bookAssetStorageService;
        private readonly ILogger<BookController> _logger;
        private const long MinPdfBytes = 1 * 1024 * 1024;
        private const long MaxPdfBytes = 100 * 1024 * 1024;
        private const long MaxImageBytes = 10 * 1024 * 1024;
        private static readonly HashSet<string> AllowedImageContentTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/webp"
        };

        public BookController(
            ISender sender,
            IBookAssetStorageService bookAssetStorageService,
            ILogger<BookController> logger)
        {
            _sender = sender;
            _bookAssetStorageService = bookAssetStorageService;
            _logger = logger;
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetBookById(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetBookQuery(id), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [HttpGet("{id:guid}/assets")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> GetBookAssetLinks(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetBookAssetLinksQuery(id), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [HttpGet]
        public async Task<IActionResult> GetBooks(
            [FromQuery] string? searchTerm,
            [FromQuery] Guid? authorId,
            [FromQuery] Guid? genreId,
            [FromQuery] decimal? minPrice,
            [FromQuery] decimal? maxPrice,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 12,
            CancellationToken cancellationToken = default)
        {
            var result = await _sender.Send(new GetAllBooksQuery(searchTerm, authorId, genreId, minPrice, maxPrice, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpGet("home")]
        public async Task<IActionResult> GetHomeFeed(
            [FromQuery] string? searchTerm,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 12,
            [FromQuery] int takeRecommendations = 5,
            CancellationToken cancellationToken = default)
        {
            var booksResult = await _sender.Send(
                new GetAllBooksQuery(searchTerm, null, null, null, null, page, pageSize),
                cancellationToken);

            if (!booksResult.IsSuccess)
            {
                return BadRequest(booksResult.Error);
            }

            if (User.Identity?.IsAuthenticated != true)
            {
                return Ok(new HomeFeedResponse(
                    booksResult.Value.Items,
                    booksResult.Value.Page,
                    booksResult.Value.PageSize,
                    booksResult.Value.TotalCount,
                    booksResult.Value.TotalPages,
                    booksResult.Value.HasPreviousPage,
                    booksResult.Value.HasNextPage,
                    new List<RecommendedBookResponse>()));
            }

            try
            {
                var recommendationsResult = await _sender.Send(
                    new GetRecommendedBooksQuery(User.GetRequiredUserId(), takeRecommendations),
                    cancellationToken);

                if (!recommendationsResult.IsSuccess)
                {
                    _logger.LogWarning(
                        "Home feed recommendations failed for user {UserId}. Error: {ErrorCode}",
                        User.GetRequiredUserId(),
                        recommendationsResult.Error.Code);
                    return Ok(new HomeFeedResponse(
                        booksResult.Value.Items,
                        booksResult.Value.Page,
                        booksResult.Value.PageSize,
                        booksResult.Value.TotalCount,
                        booksResult.Value.TotalPages,
                        booksResult.Value.HasPreviousPage,
                        booksResult.Value.HasNextPage,
                        new List<RecommendedBookResponse>()));
                }

                return Ok(new HomeFeedResponse(
                    booksResult.Value.Items,
                    booksResult.Value.Page,
                    booksResult.Value.PageSize,
                    booksResult.Value.TotalCount,
                    booksResult.Value.TotalPages,
                    booksResult.Value.HasPreviousPage,
                    booksResult.Value.HasNextPage,
                    recommendationsResult.Value));
            }
            catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
            {
                _logger.LogWarning(
                    "Home feed recommendations timed out for user {UserId}. Returning books without recommendations.",
                    User.GetRequiredUserId());
                return Ok(new HomeFeedResponse(
                    booksResult.Value.Items,
                    booksResult.Value.Page,
                    booksResult.Value.PageSize,
                    booksResult.Value.TotalCount,
                    booksResult.Value.TotalPages,
                    booksResult.Value.HasPreviousPage,
                    booksResult.Value.HasNextPage,
                    new List<RecommendedBookResponse>()));
            }
        }

        [HttpGet("admin-page")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> GetAdminBooksPage(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 12,
            CancellationToken cancellationToken = default)
        {
            var booksResult = await _sender.Send(
                new GetAllBooksQuery(null, null, null, null, null, page, pageSize),
                cancellationToken);
            var authorsResult = await _sender.Send(
                new GetAllAuthorsQuery(null, 1, 200),
                cancellationToken);
            var genresResult = await _sender.Send(
                new GetAllGenresQuery(null, 1, 200),
                cancellationToken);
            if (!booksResult.IsSuccess)
            {
                return BadRequest(booksResult.Error);
            }

            if (!authorsResult.IsSuccess)
            {
                return BadRequest(authorsResult.Error);
            }

            if (!genresResult.IsSuccess)
            {
                return BadRequest(genresResult.Error);
            }

            return Ok(new AdminBooksPageResponse(
                booksResult.Value.Items,
                booksResult.Value.Page,
                booksResult.Value.PageSize,
                booksResult.Value.TotalCount,
                booksResult.Value.TotalPages,
                booksResult.Value.HasPreviousPage,
                booksResult.Value.HasNextPage,
                authorsResult.Value.Items,
                genresResult.Value.Items));
        }

        [HttpPost]
        [Authorize(Roles = ApplicationRoles.Admin)]
        [Consumes("multipart/form-data")]
        public Task<IActionResult> AddBook([FromForm] AddNewBookRequest request, CancellationToken cancellationToken) =>
            CreateBookAsync(request, cancellationToken);

        [HttpPut("{id:guid}")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        [Consumes("multipart/form-data")]
        public Task<IActionResult> UpdateBook(Guid id, [FromForm] UpdateBookRequest request, CancellationToken cancellationToken) =>
            UpdateBookAsync(id, request, cancellationToken);

        [HttpDelete("{id:guid}")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> DeleteBook(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new DeleteBookCommand(id), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }

        private async Task<IActionResult> CreateBookAsync(AddNewBookRequest request, CancellationToken cancellationToken)
        {
            var bookLinksResult = await BuildBookLinksAsync(
                request.PdfLink,
                request.ImageLink,
                request.PdfFile,
                request.ImageFile,
                cancellationToken);

            if (!bookLinksResult.IsSuccess)
            {
                return BadRequest(bookLinksResult.Error);
            }

            var command = new MakeNewBookCommand(
                new LibroSphere.Domain.Entities.Books.Title(request.Title),
                new LibroSphere.Domain.Entities.Books.Description(request.Description),
                new Money(request.PriceAmount, Currency.FromCode(request.CurrencyCode)),
                bookLinksResult.Value,
                request.AuthorId,
                request.GenreIds ?? new List<Guid>());

            var result = await _sender.Send(command, cancellationToken);
            if (!result.IsSuccess)
            {
                return BadRequest(result.Error);
            }

            var assetsResult = await _sender.Send(new GetBookAssetLinksQuery(result.Value), cancellationToken);
            return assetsResult.IsSuccess
                ? CreatedAtAction(nameof(GetBookAssetLinks), new { id = result.Value }, assetsResult.Value)
                : CreatedAtAction(nameof(GetBookById), new { id = result.Value }, new { bookId = result.Value });
        }

        private async Task<IActionResult> UpdateBookAsync(Guid id, UpdateBookRequest request, CancellationToken cancellationToken)
        {
            var bookLinksResult = await BuildBookLinksAsync(
                request.PdfLink,
                request.ImageLink,
                request.PdfFile,
                request.ImageFile,
                cancellationToken);

            if (!bookLinksResult.IsSuccess)
            {
                return BadRequest(bookLinksResult.Error);
            }

            var command = new UpdateBookCommand(
                id,
                new LibroSphere.Domain.Entities.Books.Title(request.Title),
                new LibroSphere.Domain.Entities.Books.Description(request.Description),
                new Money(request.PriceAmount, Currency.FromCode(request.CurrencyCode)),
                bookLinksResult.Value,
                request.AuthorId,
                request.GenreIds ?? new List<Guid>());

            var result = await _sender.Send(command, cancellationToken);
            if (!result.IsSuccess)
            {
                return BadRequest(result.Error);
            }

            var assetsResult = await _sender.Send(new GetBookAssetLinksQuery(id), cancellationToken);
            return assetsResult.IsSuccess ? Ok(assetsResult.Value) : NoContent();
        }

        private async Task<Result<LibroSphere.Domain.Entities.Books.BookLinks>> BuildBookLinksAsync(
            string? pdfLink,
            string? imageLink,
            IFormFile? pdfFile,
            IFormFile? imageFile,
            CancellationToken cancellationToken)
        {
            if (pdfFile is not null)
            {
                if (pdfFile.Length < MinPdfBytes || pdfFile.Length > MaxPdfBytes || !HasValidPdfContentType(pdfFile))
                {
                    return Result.Failure<LibroSphere.Domain.Entities.Books.BookLinks>(new Error("Book.InvalidPdfFile", "PDF file must be a valid PDF between 1MB and 100MB."));
                }

                await using var pdfStream = pdfFile.OpenReadStream();
                pdfLink = (await _bookAssetStorageService.UploadPdfAsync(
                    pdfStream,
                    pdfFile.FileName,
                    pdfFile.ContentType,
                    cancellationToken)).StoredValue;
            }

            if (imageFile is not null)
            {
                if (imageFile.Length == 0 || imageFile.Length > MaxImageBytes || !AllowedImageContentTypes.Contains(imageFile.ContentType))
                {
                    return Result.Failure<LibroSphere.Domain.Entities.Books.BookLinks>(new Error("Book.InvalidImageFile", "Image file must be jpg, jpeg, png or webp and smaller than 10MB."));
                }

                await using var imageStream = imageFile.OpenReadStream();
                imageLink = (await _bookAssetStorageService.UploadImageAsync(
                    imageStream,
                    imageFile.FileName,
                    imageFile.ContentType,
                    cancellationToken)).StoredValue;
            }

            if (string.IsNullOrWhiteSpace(pdfLink))
            {
                return Result.Failure<LibroSphere.Domain.Entities.Books.BookLinks>(new Error("Book.PdfRequired", "PDF link or PDF file is required."));
            }

            if (string.IsNullOrWhiteSpace(imageLink))
            {
                return Result.Failure<LibroSphere.Domain.Entities.Books.BookLinks>(new Error("Book.ImageRequired", "Image link or image file is required."));
            }

            return Result.Success(new LibroSphere.Domain.Entities.Books.BookLinks(pdfLink.Trim(), imageLink.Trim()));
        }

        private static bool HasValidPdfContentType(IFormFile pdfFile)
        {
            if (string.Equals(pdfFile.ContentType, "application/pdf", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            return string.Equals(pdfFile.ContentType, "application/octet-stream", StringComparison.OrdinalIgnoreCase)
                && string.Equals(Path.GetExtension(pdfFile.FileName), ".pdf", StringComparison.OrdinalIgnoreCase);
        }
    }

    public sealed record HomeFeedResponse(
        IReadOnlyList<BookResponse> Newest,
        int Page,
        int PageSize,
        int TotalCount,
        int TotalPages,
        bool HasPreviousPage,
        bool HasNextPage,
        IReadOnlyList<RecommendedBookResponse> Recommendations);

    public sealed record AdminBooksPageResponse(
        IReadOnlyList<BookResponse> Books,
        int Page,
        int PageSize,
        int TotalCount,
        int TotalPages,
        bool HasPreviousPage,
        bool HasNextPage,
        IReadOnlyList<AuthorResponse> Authors,
        IReadOnlyList<GenreResponse> Genres);
}
