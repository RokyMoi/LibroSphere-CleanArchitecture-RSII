using LibroSphere.Application.Books.Command.CreateNewBook;
using LibroSphere.Application.Books.Command.DeleteBook;
using LibroSphere.Application.Books.Command.UpdateBook;
using LibroSphere.Application.Books.Query.GetAllBooks;
using LibroSphere.Application.Books.Query.GetBookAssetLinksById;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Shared;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Book
{
    [Route("api/[controller]")]
    [ApiController]
    public class BookController : ControllerBase
    {
        private readonly ISender _sender;
        private readonly IBookAssetStorageService _bookAssetStorageService;
        private const long MaxPdfBytes = 100 * 1024 * 1024;
        private const long MaxImageBytes = 10 * 1024 * 1024;
        private static readonly HashSet<string> AllowedImageContentTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/webp"
        };

        public BookController(ISender sender, IBookAssetStorageService bookAssetStorageService)
        {
            _sender = sender;
            _bookAssetStorageService = bookAssetStorageService;
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

        [HttpPost]
        [Authorize(Roles = ApplicationRoles.Admin)]
        [Consumes("application/json")]
        public Task<IActionResult> AddBook([FromBody] AddNewBookRequest request, CancellationToken cancellationToken) =>
            CreateBookAsync(request, cancellationToken);

        [HttpPost]
        [Authorize(Roles = ApplicationRoles.Admin)]
        [Consumes("multipart/form-data")]
        public Task<IActionResult> AddBookWithFiles([FromForm] AddNewBookRequest request, CancellationToken cancellationToken) =>
            CreateBookAsync(request, cancellationToken);

        [HttpPut("{id:guid}")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        [Consumes("application/json")]
        public Task<IActionResult> UpdateBook(Guid id, [FromBody] UpdateBookRequest request, CancellationToken cancellationToken) =>
            UpdateBookAsync(id, request, cancellationToken);

        [HttpPut("{id:guid}")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        [Consumes("multipart/form-data")]
        public Task<IActionResult> UpdateBookWithFiles(Guid id, [FromForm] UpdateBookRequest request, CancellationToken cancellationToken) =>
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
                request.AuthorId);

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
                if (pdfFile.Length == 0 || pdfFile.Length > MaxPdfBytes || !string.Equals(pdfFile.ContentType, "application/pdf", StringComparison.OrdinalIgnoreCase))
                {
                    return Result.Failure<LibroSphere.Domain.Entities.Books.BookLinks>(new Error("Book.InvalidPdfFile", "PDF file must be a non-empty PDF smaller than 100MB."));
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
    }
}
