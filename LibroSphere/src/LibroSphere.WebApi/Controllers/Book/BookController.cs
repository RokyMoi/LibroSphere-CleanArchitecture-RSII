using LibroSphere.Application.Books.Command.CreateNewBook;
using LibroSphere.Application.Books.Command.DeleteBook;
using LibroSphere.Application.Books.Command.UpdateBook;
using LibroSphere.Application.Common.Models;
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
        private const long MaxPdfBytes = 100 * 1024 * 1024;
        private const long MaxImageBytes = 10 * 1024 * 1024;
        private static readonly HashSet<string> AllowedImageContentTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/webp"
        };
        private static readonly byte[] PdfMagicBytes = { 0x25, 0x50, 0x44, 0x46, 0x2D }; // %PDF-
        private static readonly byte[] JpegMagicBytes = { 0xFF, 0xD8, 0xFF };
        private static readonly byte[] PngMagicBytes = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };
        private static readonly byte[] WebpRiffMagicBytes = { 0x52, 0x49, 0x46, 0x46 };
        private static readonly byte[] WebpWebpMagicBytes = { 0x57, 0x45, 0x42, 0x50 };

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
            [FromQuery] double? minRating,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 12,
            CancellationToken cancellationToken = default)
        {
            var result = await _sender.Send(new GetAllBooksQuery(searchTerm, authorId, genreId, minPrice, maxPrice, minRating, page, pageSize), cancellationToken);
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
            var booksTask = _sender.Send(
                new GetAllBooksQuery(searchTerm, null, null, null, null, null, page, pageSize),
                cancellationToken);

            if (User.Identity?.IsAuthenticated != true)
            {
                var anonymousBooksResult = await booksTask;

                if (!anonymousBooksResult.IsSuccess)
                {
                    return BadRequest(anonymousBooksResult.Error);
                }

                return Ok(CreateHomeFeedResponse(anonymousBooksResult.Value));
            }

            var userId = User.GetRequiredUserId();
            var recommendationsTask = _sender.Send(
                new GetRecommendedBooksQuery(userId, takeRecommendations),
                cancellationToken);

            var booksResult = await booksTask;

            if (!booksResult.IsSuccess)
            {
                return BadRequest(booksResult.Error);
            }

            try
            {
                var recommendationsResult = await recommendationsTask;

                if (!recommendationsResult.IsSuccess)
                {
                    _logger.LogWarning(
                        "Home feed recommendations failed for user {UserId}. Error: {ErrorCode}",
                        userId,
                        recommendationsResult.Error.Code);
                    return Ok(CreateHomeFeedResponse(booksResult.Value));
                }

                return Ok(CreateHomeFeedResponse(booksResult.Value, recommendationsResult.Value));
            }
            catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
            {
                _logger.LogWarning(
                    "Home feed recommendations timed out for user {UserId}. Returning books without recommendations.",
                    userId);
                return Ok(CreateHomeFeedResponse(booksResult.Value));
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
                new GetAllBooksQuery(null, null, null, null, null, null, page, pageSize),
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
                if (pdfFile.Length == 0 || pdfFile.Length > MaxPdfBytes)
                {
                    return Result.Failure<LibroSphere.Domain.Entities.Books.BookLinks>(new Error("Book.InvalidPdfFile", "PDF file must be greater than 0 bytes and smaller than 100MB."));
                }

                await using var pdfStream = pdfFile.OpenReadStream();
                if (!await HasValidMagicBytesAsync(pdfStream, PdfMagicBytes))
                {
                    return Result.Failure<LibroSphere.Domain.Entities.Books.BookLinks>(new Error("Book.InvalidPdfFile", "File is not a valid PDF."));
                }
                pdfStream.Position = 0;
                pdfLink = (await _bookAssetStorageService.UploadPdfAsync(
                    pdfStream,
                    pdfFile.FileName,
                    pdfFile.ContentType,
                    cancellationToken)).StoredValue;
            }

            if (imageFile is not null)
            {
                if (imageFile.Length == 0 || imageFile.Length > MaxImageBytes)
                {
                    return Result.Failure<LibroSphere.Domain.Entities.Books.BookLinks>(new Error("Book.InvalidImageFile", "Image file must be greater than 0 bytes and smaller than 10MB."));
                }

                await using var imageStream = imageFile.OpenReadStream();
                if (!await HasValidImageMagicBytesAsync(imageStream))
                {
                    return Result.Failure<LibroSphere.Domain.Entities.Books.BookLinks>(new Error("Book.InvalidImageFile", "File is not a valid JPEG, PNG, or WebP image."));
                }
                imageStream.Position = 0;
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

        private static async Task<bool> HasValidMagicBytesAsync(Stream stream, byte[] expectedBytes)
        {
            var buffer = new byte[expectedBytes.Length];
            var bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length);
            if (bytesRead < expectedBytes.Length) return false;
            for (var i = 0; i < expectedBytes.Length; i++)
            {
                if (buffer[i] != expectedBytes[i]) return false;
            }
            return true;
        }

        private static async Task<bool> HasValidImageMagicBytesAsync(Stream stream)
        {
            var buffer = new byte[12];
            var bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length);
            if (bytesRead < 4) return false;

            if (bytesRead >= 3 && buffer[0] == JpegMagicBytes[0] && buffer[1] == JpegMagicBytes[1] && buffer[2] == JpegMagicBytes[2])
                return true;

            if (bytesRead >= 8 && buffer.Take(8).SequenceEqual(PngMagicBytes))
                return true;

            if (bytesRead >= 12 && buffer.Take(4).SequenceEqual(WebpRiffMagicBytes) && buffer.Skip(8).Take(4).SequenceEqual(WebpWebpMagicBytes))
                return true;

            return false;
        }

        private static HomeFeedResponse CreateHomeFeedResponse(
            PagedResponse<BookResponse> books,
            IReadOnlyList<RecommendedBookResponse>? recommendations = null) =>
            new(
                books.Items,
                books.Page,
                books.PageSize,
                books.TotalCount,
                books.TotalPages,
                books.HasPreviousPage,
                books.HasNextPage,
                recommendations ?? Array.Empty<RecommendedBookResponse>());
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
