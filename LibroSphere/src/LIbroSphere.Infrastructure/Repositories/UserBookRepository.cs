using LibroSphere.Application.Abstractions;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
using Microsoft.EntityFrameworkCore;
using System;

namespace LibroSphere.Infrastructure.Repositories
{
    public class UserBookRepository : IUserBookRepository
    {
        private readonly ApplicationDbContext _context;

        public UserBookRepository(ApplicationDbContext context) => _context = context;

        public async Task<List<UserBook>> GetByEmailAsync(string email)
        {
            var libo = await _context.Set<UserBook>()
                .Include(ub => ub.Book)
                .Where(ub => ub.UserEmail == email)
                .ToListAsync(); return libo;
        }

        public async Task<bool> HasAccessAsync(string email, Guid bookId)
        {
            return await _context.Set<UserBook>()
                .AnyAsync(ub => ub.UserEmail == email && ub.BookId == bookId);
        }

        public async Task AddAsync(UserBook userBook)
        {
            await _context.Set<UserBook>().AddAsync(userBook);
        }
       

        public async Task SaveChangesAsync()
            => await _context.SaveChangesAsync();
    }
}