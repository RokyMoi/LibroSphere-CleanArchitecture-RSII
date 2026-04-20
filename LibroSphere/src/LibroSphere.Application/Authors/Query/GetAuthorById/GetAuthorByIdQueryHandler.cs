using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Authors.Errors;

namespace LibroSphere.Application.Authors.Query.GetAuthorById
{
    internal sealed class GetAuthorByIdQueryHandler : IQueryHandler<GetAuthorByIdQuery, AuthorResponse>
    {
        private readonly IAuthorRepository _authorRepository;

        public GetAuthorByIdQueryHandler(IAuthorRepository authorRepository)
        {
            _authorRepository = authorRepository;
        }

        public async Task<Result<AuthorResponse>> Handle(GetAuthorByIdQuery request, CancellationToken cancellationToken)
        {
            var author = await _authorRepository.GetReadOnlyByIdAsync(request.autorId, cancellationToken);
            if (author is null)
            {
                return Result.Failure<AuthorResponse>(AuthorErrors.NotFound);
            }

            return Result.Success(new AuthorResponse
            {
                Id = author.Id,
                Name = author.Name.Value,
                Biography = author.Biography.Value
            });
        }
    }
}
