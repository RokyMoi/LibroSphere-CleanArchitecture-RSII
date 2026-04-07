namespace LibroSphere.Application.Authors.Query.GetAuthorById
{
    public sealed class AuthorResponse
    {
        public Guid Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string Biography { get; init; } = string.Empty;
    }
}
