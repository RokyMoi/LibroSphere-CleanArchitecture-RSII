using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Application.Authors.Query.GetAuthorById;
using LibroSphere.Domain.Entities.Authors;

namespace LibroSphere.Application.Authors.Query.GetAllAuthors
{
    internal sealed class GetAllAuthorsQueryHandler : IQueryHandler<GetAllAuthorsQuery, PagedResponse<AuthorResponse>>
    {
        private readonly IAuthorRepository _authorRepository;

        public GetAllAuthorsQueryHandler(IAuthorRepository authorRepository)
        {
            _authorRepository = authorRepository;
        }

        public async Task<Result<PagedResponse<AuthorResponse>>> Handle(GetAllAuthorsQuery request, CancellationToken cancellationToken)
        {
            var page = Math.Max(1, request.Page);
            var pageSize = Math.Clamp(request.PageSize, 1, 200);

            var authors = await _authorRepository.GetAllAsync(cancellationToken);

            var response = authors
                .Where(author =>
                    string.IsNullOrWhiteSpace(request.SearchTerm) ||
                    author.Name.Value.Contains(request.SearchTerm, StringComparison.OrdinalIgnoreCase) ||
                    author.Biography.Value.Contains(request.SearchTerm, StringComparison.OrdinalIgnoreCase))
                .Select(author => new AuthorResponse
                {
                    Id = author.Id,
                    Name = author.Name.Value,
                    Biography = author.Biography.Value
                })
                .ToList();

            return Result.Success(PagedResponse<AuthorResponse>.Create(response, page, pageSize));
        }
    }
}
