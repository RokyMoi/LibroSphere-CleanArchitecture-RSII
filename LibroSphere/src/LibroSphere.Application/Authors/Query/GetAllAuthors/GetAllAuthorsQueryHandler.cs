using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Authors.Query.GetAuthorById;
using LibroSphere.Domain.Entities.Authors;

namespace LibroSphere.Application.Authors.Query.GetAllAuthors
{
    internal sealed class GetAllAuthorsQueryHandler : IQueryHandler<GetAllAuthorsQuery, List<AuthorResponse>>
    {
        private readonly IAuthorRepository _authorRepository;

        public GetAllAuthorsQueryHandler(IAuthorRepository authorRepository)
        {
            _authorRepository = authorRepository;
        }

        public async Task<Result<List<AuthorResponse>>> Handle(GetAllAuthorsQuery request, CancellationToken cancellationToken)
        {
            var authors = await _authorRepository.GetAllAsync(cancellationToken);

            var response = authors
                .Select(author => new AuthorResponse
                {
                    Id = author.Id,
                    Name = author.Name.Value,
                    Biography = author.Biography.Value
                })
                .ToList();

            return Result.Success(response);
        }
    }
}
