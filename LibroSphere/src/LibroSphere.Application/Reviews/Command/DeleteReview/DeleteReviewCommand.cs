using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Reviews.Command.DeleteReview
{
    public sealed record DeleteReviewCommand(Guid ReviewId, Guid UserId) : ICommand;
}
