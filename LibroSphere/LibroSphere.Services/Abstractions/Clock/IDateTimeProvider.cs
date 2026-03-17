using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Clock
{
    //We use interface because of mocking, and testing code 
    public interface IDateTimeProvider
    {
        DateTime UtcNow { get; }
    }
}
