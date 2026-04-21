using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.Notifications;

namespace LibroSphere.Application.News.Command.CreateNews;

public sealed record CreateNewsCommand(string Title, string Text, string ImageUrl)
    : ICommand<NewsItemDto>;
