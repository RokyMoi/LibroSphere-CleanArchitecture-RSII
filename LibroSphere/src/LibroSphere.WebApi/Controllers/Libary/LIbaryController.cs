namespace LibroSphere.WebApi.Controllers.Libary
{
    using global::LibroSphere.Domain.Entities.Books;
    using global::LibroSphere.Domain.Entities.ManyToMany.IRepositories;
    using LibroSphere.Application.Abstractions;
    using Microsoft.AspNetCore.Authorization;
    using Microsoft.AspNetCore.Mvc;
    using System.Security.Claims;

    namespace LibroSphere.WebApi.Controllers.Library
    {
        [Route("api/[controller]")]
        [ApiController]
        [Authorize]
        public class LibraryController : ControllerBase
        {
            private readonly IUserBookRepository _userBookRepo;
            private readonly IBookRepository _bookRepo;

            public LibraryController(IUserBookRepository userBookRepo, IBookRepository bookRepo)
            {
                _userBookRepo = userBookRepo;
                _bookRepo = bookRepo;
            }

            // GET /api/library — lista kupljenih knjiga
            [HttpGet]
            public async Task<ActionResult<List<UserBookDto>>> GetMyLibrary()
            {
                var email = User.FindFirstValue(ClaimTypes.Email)!;
                var userBooks = await _userBookRepo.GetByEmailAsync(email);

                var result = userBooks.Select(ub => new UserBookDto(
                    ub.BookId,
                    ub.Book.Title.Value,
                    ub.Book.BookLinkovi.imageLink,
                    ub.PurchasedAt
                )).ToList();

                return Ok(result);
            }

            // GET /api/library/{bookId}/read — vraca PDF link
            [HttpGet("{bookId:guid}/read")]
            public async Task<IActionResult> GetPdfLink(Guid bookId)
            {
                var email = User.FindFirstValue(ClaimTypes.Email)!;

                var hasAccess = await _userBookRepo.HasAccessAsync(email, bookId);
                if (!hasAccess) return Forbid();

                var book = await _bookRepo.GetAsyncById(bookId);
                if (book == null) return NotFound();

                return Ok(new { pdfUrl = book.BookLinkovi.PdfLink });
            }
        }

        public record UserBookDto(
            Guid BookId,
            string Title,
            string? ImageLink,
            DateTime PurchasedAt
        );
    }
}
