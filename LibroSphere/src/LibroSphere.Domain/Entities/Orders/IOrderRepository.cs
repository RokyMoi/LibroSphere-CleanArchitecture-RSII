using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Abstractions
{
    public interface IOrderRepository
    {
        Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
        Task<Order?> GetByPaymentIntentIdAsync(string paymentIntentId, CancellationToken cancellationToken = default);
        Task<List<Order>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
        Task<List<Order>> GetAllAsync(CancellationToken cancellationToken = default);
        Task<(List<Order> Items, int TotalCount)> GetPagedForUserAsync(
            Guid userId,
            OrderStatus? status,
            int page,
            int pageSize,
            CancellationToken cancellationToken = default);
        Task<(List<Order> Items, int TotalCount)> GetPagedAsync(
            string? searchTerm,
            OrderStatus? status,
            int page,
            int pageSize,
            CancellationToken cancellationToken = default);
        Task AddAsync(Order order, CancellationToken cancellationToken = default);
        Task SaveChangesAsync(CancellationToken cancellationToken = default);
    }
}
