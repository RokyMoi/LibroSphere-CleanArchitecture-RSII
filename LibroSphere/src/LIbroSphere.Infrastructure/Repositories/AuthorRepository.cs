
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Infrastructure.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LIbroSphere.Infrastructure.Repositories
{
    internal sealed class AuthorRepository : RepositoryBase<Author>, IAuthorRepository
    {
        public AuthorRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

 
    }
}
