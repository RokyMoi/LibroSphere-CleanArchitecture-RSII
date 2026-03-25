
using LibroSphere.Domain.Abstractions.Clock;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LIbroSphere.Infrastructure.Clock
{
    //easy for mock, for testing purposes..Maybe later add some method depend on needs
   
    internal sealed class DateTimeProvider : IDateTimeProvider
    {
        public DateTime UtcNow => DateTime.UtcNow;
    }
}
