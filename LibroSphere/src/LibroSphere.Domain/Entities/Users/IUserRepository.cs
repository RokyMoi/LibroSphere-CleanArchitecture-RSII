using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Users
{
    public interface IUserRepository
    {
        Task<User?> GetAsyncById(Guid id, CancellationToken cancellationToken = default);
        void Add(User user);   

    }
}
