using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Authors;

namespace LibroSphere.Application.Authors.Command.DeleteAuthor
{
    public sealed record DeleteAuthorCommand(Guid AuthorId) : ICommand;
}
