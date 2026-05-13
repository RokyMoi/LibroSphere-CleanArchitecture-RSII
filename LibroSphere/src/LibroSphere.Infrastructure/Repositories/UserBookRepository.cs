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

        public async Task<List<UserBook>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            var libo = await _context.Set<UserBook>()
                .AsNoTracking()
                .AsSplitQuery()
                .Include(ub => ub.Book)
                    .ThenInclude(book => book.Author)
                .Include(ub => ub.Book)
                    .ThenInclude(book => book.Reviews)
                .Include(ub => ub.Book)
                    .ThenInclude(book => book.BookGenres)
                        .ThenInclude(bookGenre => bookGenre.Genre)
                .Where(ub => ub.UserId == userId)
                .ToListAsync(cancellationToken);

            return libo;
        }

        public async Task<bool> HasAccessAsync(Guid userId, Guid bookId)
        {
            return await _context.Set<UserBook>()
                .AnyAsync(ub => ub.UserId == userId && ub.BookId == bookId);
        }

        public async Task AddAsync(UserBook userBook)
        {
            await _context.Set<UserBook>().AddAsync(userBook);
        }

        public Task RemoveAsync(UserBook userBook)
        {
            _context.Set<UserBook>().Remove(userBook);
            return Task.CompletedTask;
        }

        public async Task SaveChangesAsync()
            => await _context.SaveChangesAsync();
    }
}
