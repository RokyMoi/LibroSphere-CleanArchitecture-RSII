using FluentValidation;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Exceptions;
using MediatR;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Behavior

{

    public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
        where TRequest : IBaseCommand
    {
        private readonly IEnumerable<IValidator<TRequest>> _validators;

        public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
        {
            _validators = validators;
        }

        public async Task<TResponse> Handle(
            TRequest request,
            RequestHandlerDelegate<TResponse> next,
            CancellationToken cancellationToken)
        {
         //If there is no validator keep on next step.
            if (!_validators.Any())
            {
                return await next();
            }

            var context = new ValidationContext<TRequest>(request);

            var validationErrors = _validators
                .Select(validator => validator.Validate(context))             // Validira kontekst
                .Where(validationResult => validationResult.Errors.Any())    // Uzima samo rezultate sa greškama
                .SelectMany(validationResult => validationResult.Errors)     // Raspakuje listu grešaka
                .Select(validationFailure => new ValidationError(           // Kreira listu ValidationError objekata
                    validationFailure.PropertyName,
                    validationFailure.ErrorMessage))
                .ToList();

            if (validationErrors.Any())
            {
                throw new Exceptions.ValidationExceptions(validationErrors);
            }

          return await next();
        }
    }
}