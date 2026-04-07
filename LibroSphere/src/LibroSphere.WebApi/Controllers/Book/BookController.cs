using LibroSphere.Application.Books.Command.CreateNewBook;
using LibroSphere.Application.Books.Command.DeleteBook;
using LibroSphere.Application.Books.Command.UpdateBook;
using LibroSphere.Application.Books.Query.GetAllBooks;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Domain.Entities.Shared;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Book
{
    [Route("api/[controller]")]
    [ApiController]
    public class BookController : ControllerBase
    {
        private readonly ISender _sender;

        public BookController(ISender sender)
        {
            _sender = sender;
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetBookById(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetBookQuery(id), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [HttpGet]
        public async Task<IActionResult> GetBooks(
            [FromQuery] string? searchTerm,
            [FromQuery] Guid? authorId,
            [FromQuery] Guid? genreId,
            CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetAllBooksQuery(searchTerm, authorId, genreId), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpPost]
        public async Task<IActionResult> AddBook(AddNewBookRequest request, CancellationToken cancellationToken)
        {
            var command = new MakeNewBookCommand(
                new LibroSphere.Domain.Entities.Books.Title(request.Title),
                new LibroSphere.Domain.Entities.Books.Description(request.Description),
                new Money(request.PriceAmount, Currency.FromCode(request.CurrencyCode)),
                new LibroSphere.Domain.Entities.Books.BookLinks(request.PdfLink, request.ImageLink),
                request.AuthorId);

            var result = await _sender.Send(command, cancellationToken);
            return result.IsSuccess
                ? CreatedAtAction(nameof(GetBookById), new { id = result.Value }, result.Value)
                : BadRequest(result.Error);
        }

        [HttpPut("{id:guid}")]
        public async Task<IActionResult> UpdateBook(Guid id, UpdateBookRequest request, CancellationToken cancellationToken)
        {
            var command = new UpdateBookCommand(
                id,
                new LibroSphere.Domain.Entities.Books.Title(request.Title),
                new LibroSphere.Domain.Entities.Books.Description(request.Description),
                new Money(request.PriceAmount, Currency.FromCode(request.CurrencyCode)),
                new LibroSphere.Domain.Entities.Books.BookLinks(request.PdfLink, request.ImageLink),
                request.AuthorId,
                request.GenreIds ?? new List<Guid>());

            var result = await _sender.Send(command, cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> DeleteBook(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new DeleteBookCommand(id), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }
    }
}
