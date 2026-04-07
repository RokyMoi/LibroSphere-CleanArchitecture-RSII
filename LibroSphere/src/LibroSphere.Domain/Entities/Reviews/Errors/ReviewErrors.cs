using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Domain.Entities.Reviews.Errors
{
    public static class ReviewErrors
    {
        public static readonly Error NotFound = new("Review.NotFound", "Review with specified identifier was not found");
        public static readonly Error AlreadyExists = new("Review.AlreadyExists", "Review for this user and book already exists");
    }
}
