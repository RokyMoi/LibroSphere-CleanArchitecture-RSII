using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Messaging
{
    public interface ICommandHandler<TCommand>:IRequestHandler<TCommand,Result>
        where TCommand : ICommand
    {
    }

    ///Which accepts a command that can return response. <- Idea behind second one
  
    public interface ICommandHandler<TCommand,TResponse> : IRequestHandler<TCommand, Result<TResponse>>
      where TCommand : ICommand<TResponse>
    {
    }
}
