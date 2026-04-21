using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.News.Command.DeleteNews;

public sealed record DeleteNewsCommand(string Id) : ICommand;
