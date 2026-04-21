using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Abstractions
{
    public interface IOrderService
    {
        Task<Result<Order>> CreateOrderAsync(string buyerEmail, string cartId);
        Task<List<Order>> GetOrdersForUserAsync(string email);
        Task<List<Order>> GetAllOrdersAsync(CancellationToken cancellationToken = default);
        Task<Order?> GetOrderByIdAsync(Guid id);
        Task SaveChangesAsync(CancellationToken cancellationToken = default);
    }
}
