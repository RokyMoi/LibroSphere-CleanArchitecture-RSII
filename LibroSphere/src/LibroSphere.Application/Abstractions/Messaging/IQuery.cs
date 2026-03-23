using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Messaging
{
   
    //What is type call of this query : leverage mediator to implement IQuery interface, 
    //Result<TResponse - COMING FROM QUERY>
    public interface IQuery<TResponse>:IRequest<Result<TResponse>>
    {
    }
}
