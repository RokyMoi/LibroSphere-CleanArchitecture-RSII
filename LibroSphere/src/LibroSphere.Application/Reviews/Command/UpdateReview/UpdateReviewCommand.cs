using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Reviews.Command.UpdateReview
{
    public sealed record UpdateReviewCommand(Guid ReviewId, Guid UserId, int Rating, string Comment) : ICommand;
}
