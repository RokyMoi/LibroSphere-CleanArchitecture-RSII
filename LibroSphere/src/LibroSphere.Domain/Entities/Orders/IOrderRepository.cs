using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Abstractions
{
    public interface IOrderRepository
    {
        Task<Order?> GetByIdAsync(Guid id);
        Task<Order?> GetByPaymentIntentIdAsync(string paymentIntentId);
        Task<List<Order>> GetByUserIdAsync(Guid userId);
        Task<List<Order>> GetAllAsync(CancellationToken cancellationToken = default);
        Task AddAsync(Order order);
        Task SaveChangesAsync();
    }
}
