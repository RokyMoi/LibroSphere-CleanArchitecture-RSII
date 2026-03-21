using LibroSphere.Application.Books.Command.CreateNewBook;
using LibroSphere.Application.Books.Query.GetBookByIdQuery;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Shared;
using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BookController : ControllerBase
    {
        private readonly ISender sender;

        public BookController(ISender sender)
        {
            this.sender = sender;
        }
        [HttpGet("{id}")]
        public async Task<IActionResult> GetBookById(Guid id, CancellationToken cancellationToken) 
        {
        var query = new GetBookQuery(id);   
        var result = await sender.Send(query, cancellationToken);
            return result.IsSuccess ? Ok(result) : NotFound();
        }

        [HttpPost]
        public async Task<IActionResult> AddBook(AddNewBookRequest request,CancellationToken cancellationToken)
        {
            var command = new MakeNewBookCommand(
           title: new Title(request.Title),
              description: new Description(request.Description),
              price: new Money(request.PriceAmount, Currency.FromCode(request.CurrencyCode)),
             bookLinks: new BookLinks(request.PdfLink, request.ImageLink),
            authorId: request.AuthorId
             );

            var result = await sender.Send(command, cancellationToken);
            if (result.IsFailure)
            {
                return BadRequest(result.Error);
            }
            return CreatedAtAction(
    nameof(GetBookById),
    new { id = result.Value },
    result.Value
        );
        }

    }

}
