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

        public async Task<Order?> GetByIdAsync(Guid id)
        {
            return await _context.Set<Order>()
                .Include(o => o.Items)
                .FirstOrDefaultAsync(o => o.Id == id);
        }

        public async Task<Order?> GetByPaymentIntentIdAsync(string intentId)
        {
            return await _context.Set<Order>()
                .Include(o => o.Items)
                .FirstOrDefaultAsync(o => o.PaymentIntentId == intentId);
        }

        public async Task<List<Order>> GetByEmailAsync(string email)
        {
            return await _context.Set<Order>()
                .AsNoTracking()
                .Include(o => o.Items)
                .Where(o => o.BuyerEmail == email)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();
        }

        public async Task AddAsync(Order order)
        {
            await _context.Set<Order>().AddAsync(order);
        }

        public async Task SaveChangesAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}
