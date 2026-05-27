using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Abstractions
{
    public interface IOrderService
    {
        Task<Result<Order>> CreateOrderAsync(
            string buyerEmail,
            Guid userId,
            string cartId,
            string paymentIntentId,
            CancellationToken cancellationToken = default);
        Task<List<Order>> GetOrdersForUserAsync(Guid userId);
        Task<List<Order>> GetAllOrdersAsync(CancellationToken cancellationToken = default);
        Task<Order?> GetOrderByIdAsync(Guid id);
        Task SaveChangesAsync(CancellationToken cancellationToken = default);
    }
}
