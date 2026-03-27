using LibroSphere.Application.Authors.Command.CreateNewAuthor;
using LibroSphere.Application.Authors.Query.GetAuthorById;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Authors.Errors;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Author
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthorController : ControllerBase
    {
        private readonly ISender sender;
        private readonly IAuthorRepository _repository;

        public AuthorController(ISender sender, IAuthorRepository repository)
        {
            this.sender = sender;
            _repository = repository;
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetAuthorById(Guid id, CancellationToken cancellaction)
        {
            var query = new GetAuthorByIdQuery(id);
            var result = await sender.Send(query,cancellaction);
             return  result.IsSuccess ? Ok(result) : NotFound();


        }
        [HttpPost]

        public async Task<IActionResult> MakeANewAuthor(AddNewAuthorRequest request, CancellationToken cancellaction)
        {
            var command = new MakeANewAuthorCommand(new Name(request.Name), 
                new Biography(request.Biography));

            var result = await sender.Send(command,cancellaction);

            return result.IsSuccess ?  CreatedAtAction(
           nameof(GetAuthorById),
     new { id = result.Value },
    result.Value
        ) : BadRequest(result.Error);
        }
    }

    }

