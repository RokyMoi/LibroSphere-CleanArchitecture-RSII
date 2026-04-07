using LibroSphere.Application.Abstractions.Messaging;
using MediatR;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Behavior
{
    public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
        where TRequest : IBaseCommand
        //// So wee want just to do logging on command pipeline, cuz we want to get our queries fastest possible.
        //Its interface from MediatR  so we can proccess some information after or before our request.
        ///Logging orrr Validation
    {
        private readonly ILogger<TRequest> _logger;

        public LoggingBehavior(ILogger<TRequest> logger)
        {
            _logger = logger;
        }

        public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
        {
           var name= request.GetType().Name;
            try
            {
                _logger.LogInformation("Executing command {Command}", name);
                var result = await next();
                _logger.LogInformation("Command {Command} processed sucessfully", name);
                return result;

            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Command {Command} proccessing failed", name);
                throw;
            }
        }
    }
}
