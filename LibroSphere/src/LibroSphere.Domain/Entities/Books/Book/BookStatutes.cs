using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Books
{
    public enum BookStatutes
    {
        WantToRead = 0,
        Reading = 1,
        Read = 2,
        Dropped = 3,
        OnHold = 4
    }
}
