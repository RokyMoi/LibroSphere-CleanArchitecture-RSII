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

namespace LibroSphere.Domain.Entities.Books
{
    public interface IBookRepository
    {
        Task<Book?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        void Add(Book book);

    }
}
