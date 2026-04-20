using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;

namespace LibroSphere.Application.Library.Query.GetBookReadLink
{
    internal sealed class GetBookReadLinkQueryHandler : IQueryHandler<GetBookReadLinkQuery, string>
    {
        private readonly IUserBookRepository _userBookRepository;
        private readonly IBookRepository _bookRepository;
        private readonly IBookAssetStorageService _bookAssetStorageService;

        public GetBookReadLinkQueryHandler(
            IUserBookRepository userBookRepository,
            IBookRepository bookRepository,
            IBookAssetStorageService bookAssetStorageService)
        {
            _userBookRepository = userBookRepository;
            _bookRepository = bookRepository;
            _bookAssetStorageService = bookAssetStorageService;
        }

        public async Task<Result<string>> Handle(GetBookReadLinkQuery request, CancellationToken cancellationToken)
        {
            var hasAccess = await _userBookRepository.HasAccessAsync(request.Email, request.BookId);
            if (!hasAccess)
            {
                return Result.Failure<string>(Error.NullValue);
            }

            var book = await _bookRepository.GetReadOnlyByIdAsync(request.BookId, cancellationToken);
            return book is not null
                ? Result.Success(await _bookAssetStorageService.GetPdfReadUrlAsync(book.BookLinkovi.PdfLink, cancellationToken))
                : Result.Failure<string>(Error.NullValue);
        }
    }
}
