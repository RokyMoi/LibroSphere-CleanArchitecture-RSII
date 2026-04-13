using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Reviews.Command.CreateReview
{
    public sealed record CreateReviewCommand(Guid UserId, Guid BookId, int Rating, string Comment) : ICommand<Guid>;
}
