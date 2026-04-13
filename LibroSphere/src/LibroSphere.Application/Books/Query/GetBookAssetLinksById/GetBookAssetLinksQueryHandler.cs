using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Errors;

namespace LibroSphere.Application.Books.Query.GetBookAssetLinksById;

internal sealed class GetBookAssetLinksQueryHandler : IQueryHandler<GetBookAssetLinksQuery, BookAssetLinksResponse>
{
    private readonly IBookRepository _bookRepository;
    private readonly IBookAssetStorageService _bookAssetStorageService;

    public GetBookAssetLinksQueryHandler(
        IBookRepository bookRepository,
        IBookAssetStorageService bookAssetStorageService)
    {
        _bookRepository = bookRepository;
        _bookAssetStorageService = bookAssetStorageService;
    }

    public async Task<Result<BookAssetLinksResponse>> Handle(GetBookAssetLinksQuery request, CancellationToken cancellationToken)
    {
        var book = await _bookRepository.GetByIdWithDetailsAsync(request.BookId, cancellationToken);
        if (book is null)
        {
            return Result.Failure<BookAssetLinksResponse>(BookErrors.NotFound);
        }

        var pdfLink = await _bookAssetStorageService.GetPdfReadUrlAsync(book.BookLinkovi.PdfLink, cancellationToken);
        var imageLink = await _bookAssetStorageService.GetImageUrlAsync(book.BookLinkovi.imageLink, cancellationToken);

        return Result.Success(new BookAssetLinksResponse
        {
            BookId = book.Id,
            PdfLink = pdfLink,
            ImageLink = imageLink
        });
    }
}
