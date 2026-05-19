namespace LibroSphere.Domain.Entities.Users
{
    public sealed class UserFavoriteAuthor
    {
        public Guid UserId { get; set; }
        public Guid AuthorId { get; set; }
    }
}
