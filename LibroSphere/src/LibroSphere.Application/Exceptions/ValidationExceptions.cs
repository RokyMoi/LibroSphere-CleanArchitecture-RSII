using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Exceptions
{
    public sealed class ValidationExceptions : Exception
    {
        public ValidationExceptions(IEnumerable<ValidationError> errors)
        {
            Errors = errors;
        }
        public IEnumerable<ValidationError> Errors { get; }
    }
}
