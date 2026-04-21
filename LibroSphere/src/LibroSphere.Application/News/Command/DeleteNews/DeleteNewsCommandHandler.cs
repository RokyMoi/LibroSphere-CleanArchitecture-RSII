using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.News.Command.DeleteNews;

internal sealed class DeleteNewsCommandHandler
    : ICommandHandler<DeleteNewsCommand>
{
    private readonly INewsService _newsService;

    public DeleteNewsCommandHandler(INewsService newsService)
    {
        _newsService = newsService;
    }

    public async Task<Result> Handle(
        DeleteNewsCommand request,
        CancellationToken cancellationToken)
    {
        var deleted = await _newsService.DeleteAsync(request.Id, cancellationToken);

        return deleted
            ? Result.Success()
            : Result.Failure(new Error("News.NotFound", "News item was not found."));
    }
}
