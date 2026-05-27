using LibroSphere.Application.Abstractions;
using LibroSphere.Domain.Entities.Orders;
using Microsoft.EntityFrameworkCore;
using System;

namespace LibroSphere.Infrastructure.Repositories
{
    internal class OrderRepository : RepositoryBase<Order>,IOrderRepository
    {
        private readonly ApplicationDbContext _context;

        public OrderRepository(ApplicationDbContext context) :base(context)=> _context = context;

        public async Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return await _context.Set<Order>()
                .Include(o => o.Items)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);
        }

        public async Task<Order?> GetByPaymentIntentIdAsync(string intentId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<Order>()
                .Include(o => o.Items)
                .FirstOrDefaultAsync(o => o.PaymentIntentId == intentId, cancellationToken);
        }

        public async Task<List<Order>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<Order>()
                .AsNoTracking()
                .Include(o => o.Items)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync(cancellationToken);
        }

        public async Task<List<Order>> GetAllAsync(CancellationToken cancellationToken = default)
        {
            return await _context.Set<Order>()
                .AsNoTracking()
                .Include(o => o.Items)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync(cancellationToken);
        }

        public async Task AddAsync(Order order, CancellationToken cancellationToken = default)
        {
            await _context.Set<Order>().AddAsync(order, cancellationToken);
        }

        public async Task SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
    }
}
