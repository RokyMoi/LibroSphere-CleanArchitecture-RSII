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

        public async Task<(List<UserBook> Items, int TotalCount)> GetPagedByUserIdAsync(
            Guid userId,
            string? searchTerm,
            int page,
            int pageSize,
            CancellationToken cancellationToken = default)
        {
            var filteredQuery = _context.Set<UserBook>()
                .AsNoTracking()
                .Where(ub => ub.UserId == userId);

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.Trim();
                filteredQuery = filteredQuery.Where(ub => ub.Book.Title.Value.Contains(term));
            }

            var totalCount = await filteredQuery.CountAsync(cancellationToken);

            var pageItems = await filteredQuery
                .OrderByDescending(ub => ub.PurchasedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .AsSplitQuery()
                .Include(ub => ub.Book)
                    .ThenInclude(book => book.Author)
                .Include(ub => ub.Book)
                    .ThenInclude(book => book.BookGenres)
                        .ThenInclude(bookGenre => bookGenre.Genre)
                .ToListAsync(cancellationToken);

            return (pageItems, totalCount);
        }

        public async Task<bool> HasAccessAsync(Guid userId, Guid bookId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<UserBook>()
                .AnyAsync(ub => ub.UserId == userId && ub.BookId == bookId, cancellationToken);
        }

        public async Task<HashSet<Guid>> GetOwnedBookIdsAsync(
            Guid userId,
            IEnumerable<Guid> bookIds,
            CancellationToken cancellationToken = default)
        {
            var ids = bookIds.ToList();
            var owned = await _context.Set<UserBook>()
                .Where(ub => ub.UserId == userId && ids.Contains(ub.BookId))
                .Select(ub => ub.BookId)
                .ToListAsync(cancellationToken);
            return owned.ToHashSet();
        }

        public async Task AddAsync(UserBook userBook)
        {
            await _context.Set<UserBook>().AddAsync(userBook);
        }

        public async Task<bool> AddIfNotExistsAsync(UserBook userBook, CancellationToken cancellationToken = default)
        {
            var alreadyOwned = await _context.Set<UserBook>()
                .AnyAsync(ub => ub.UserId == userBook.UserId && ub.BookId == userBook.BookId, cancellationToken);
            if (alreadyOwned)
            {
                return false;
            }

            await _context.Set<UserBook>().AddAsync(userBook, cancellationToken);
            try
            {
                await _context.SaveChangesAsync(cancellationToken);
                return true;
            }
            catch (DbUpdateException)
            {
                // Detach our copy so it can't poison a later SaveChanges.
                _context.Entry(userBook).State = EntityState.Detached;

                // If a concurrent delivery inserted the same (UserId, BookId) row first, treat
                // the grant as already done. Otherwise the failure is unrelated — rethrow.
                var grantedConcurrently = await _context.Set<UserBook>()
                    .AnyAsync(ub => ub.UserId == userBook.UserId && ub.BookId == userBook.BookId, cancellationToken);
                if (grantedConcurrently)
                {
                    return false;
                }

                throw;
            }
        }

        public Task RemoveAsync(UserBook userBook)
        {
            _context.Set<UserBook>().Remove(userBook);
            return Task.CompletedTask;
        }

        public void RemoveRange(IEnumerable<UserBook> userBooks)
        {
            _context.Set<UserBook>().RemoveRange(userBooks);
        }

        public async Task SaveChangesAsync()
            => await _context.SaveChangesAsync();
    }
}
