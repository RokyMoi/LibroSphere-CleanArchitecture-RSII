namespace LibroSphere.Application.Reviews
{
    public sealed record ReviewResponse(
        Guid Id,
        Guid UserId,
        Guid BookId,
        int Rating,
        string Comment,
        DateTime CreatedAt);
}
