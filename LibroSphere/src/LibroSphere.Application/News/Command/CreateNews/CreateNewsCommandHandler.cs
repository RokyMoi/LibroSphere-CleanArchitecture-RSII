using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.News.Command.CreateNews;

internal sealed class CreateNewsCommandHandler
    : ICommandHandler<CreateNewsCommand, NewsItemDto>
{
    private readonly INewsService _newsService;

    public CreateNewsCommandHandler(INewsService newsService)
    {
        _newsService = newsService;
    }

    public async Task<Result<NewsItemDto>> Handle(
        CreateNewsCommand request,
        CancellationToken cancellationToken)
    {
        var created = await _newsService.CreateAsync(
            request.Title.Trim(),
            request.Text.Trim(),
            request.ImageUrl.Trim(),
            cancellationToken);

        return Result.Success(created);
    }
}
