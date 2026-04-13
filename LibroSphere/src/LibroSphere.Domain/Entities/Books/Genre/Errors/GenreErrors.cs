using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Domain.Entities.Books.Genre.Errors
{
    public static class GenreErrors
    {
        public static readonly Error NotFound = new("Genre.NotFound", "Genre with specified identifier was not found");
        public static readonly Error AlreadyExists = new("Genre.AlreadyExists", "Genre with specified name already exists");
    }
}
