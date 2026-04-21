using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;

namespace LibroSphere.Application.News.Query.GetLatestNews;

public sealed record GetLatestNewsQuery(int Take = 20)
    : IQuery<IReadOnlyCollection<NewsItemDto>>;
