using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.News.Query.GetLatestNews;

internal sealed class GetLatestNewsQueryHandler
    : IQueryHandler<GetLatestNewsQuery, IReadOnlyCollection<NewsItemDto>>
{
    private readonly INewsService _newsService;

    public GetLatestNewsQueryHandler(INewsService newsService)
    {
        _newsService = newsService;
    }

    public async Task<Result<IReadOnlyCollection<NewsItemDto>>> Handle(
        GetLatestNewsQuery request,
        CancellationToken cancellationToken)
    {
        var items = await _newsService.GetLatestAsync(request.Take, cancellationToken);
        return Result.Success(items);
    }
}
