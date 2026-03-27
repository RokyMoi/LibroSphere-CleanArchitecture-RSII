using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Authors.Query.GetAuthorById;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Authors.Errors;

internal sealed class GetAuthorByIdQueryHandler
    : IQueryHandler<GetAuthorByIdQuery, AuthorResponse>
{
    private readonly IAuthorRepository _authorRepository;

    public GetAuthorByIdQueryHandler(IAuthorRepository authorRepository)
    {
        _authorRepository = authorRepository;
    }

    public async Task<Result<AuthorResponse>> Handle(
        GetAuthorByIdQuery request,
        CancellationToken cancellationToken)
    {
        var author = await _authorRepository.GetAsyncById(
            request.autorId,
            cancellationToken
        );

        if (author is null)
        {
            return Result.Failure<AuthorResponse>(AuthorErrors.NotFound);
        }

        var response = new AuthorResponse
        {
            Id = author.Id,
            Name = author.Name.Value,
            Biography = author.Biography.Value
        };

        return Result.Success(response);
    }
}