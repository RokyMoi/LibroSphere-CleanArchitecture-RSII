using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Messaging
{
   //Two generic - Handler for our query
    public interface IQueryHandler<TQuery,TResponse>:IRequestHandler<TQuery,Result<TResponse>>
        where TQuery:IQuery<TResponse>
    {
    }
}
