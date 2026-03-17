using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Authors
{
    public interface IAuthorRepository
    {
        Task<Author?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        void Add(Author author);

    }
}
