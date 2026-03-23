using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Messaging
{
    //Ideaaa is like from query we want to make command to return result,also it will give some value for use cases

    public  interface ICommand:IRequest<Result>, IBaseCommand
    {
  
    }

    public interface ICommand<TResponse>: IRequest<Result<TResponse>>, IBaseCommand
    {
    }
  
    
    public interface IBaseCommand
    { 
    }
}
