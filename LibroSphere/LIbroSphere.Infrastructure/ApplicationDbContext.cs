using LibroSphere.Domain.Abstraction;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LIbroSphere.Infrastructure
{
    public sealed class ApplicationDbContext:DbContext,IUnitOfWork
    {
        public ApplicationDbContext(DbContextOptions options):base(options)
        {
            
        }
    }
}
