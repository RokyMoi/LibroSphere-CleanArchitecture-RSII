using LibroSphere.Domain.Entities.Recommendations;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Repositories
{
    internal sealed class CartInteractionRepository : ICartInteractionRepository
    {
        private readonly ApplicationDbContext _context;

        public CartInteractionRepository(ApplicationDbContext context) => _context = context;

        public async Task RecordAddedToCartAsync(
            Guid userId,
            IReadOnlyCollection<Guid> bookIds,
            CancellationToken cancellationToken = default)
        {
            if (bookIds is null || bookIds.Count == 0)
            {
                return;
            }

            var distinctIds = bookIds.Distinct().ToList();
            var now = DateTime.UtcNow;

            var existing = await _context.Set<CartInteraction>()
                .Where(ci => ci.UserId == userId && distinctIds.Contains(ci.BookId))
                .ToListAsync(cancellationToken);
            var existingByBook = existing.ToDictionary(ci => ci.BookId);

            foreach (var bookId in distinctIds)
            {
                if (existingByBook.TryGetValue(bookId, out var interaction))
                {
                    interaction.LastAddedAt = now;
                }
                else
                {
                    _context.Set<CartInteraction>().Add(new CartInteraction
                    {
                        UserId = userId,
                        BookId = bookId,
                        LastAddedAt = now
                    });
                }
            }

            await _context.SaveChangesAsync(cancellationToken);
        }
    }
}
