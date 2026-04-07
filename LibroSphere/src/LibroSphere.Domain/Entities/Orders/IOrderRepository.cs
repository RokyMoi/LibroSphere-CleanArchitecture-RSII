using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Abstractions
{
    public interface IOrderRepository
    {
        Task<Order?> GetByIdAsync(Guid id);
        Task<Order?> GetByPaymentIntentIdAsync(string paymentIntentId);
        Task<List<Order>> GetByEmailAsync(string email);
        Task AddAsync(Order order);
        Task SaveChangesAsync();
    }
}