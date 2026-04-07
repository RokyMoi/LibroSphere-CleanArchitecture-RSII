using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Abstractions
{
    public interface IOrderService
    {
        Task<Order> CreateOrderAsync(string buyerEmail, string cartId);
        Task<List<Order>> GetOrdersForUserAsync(string email);
        Task<Order?> GetOrderByIdAsync(Guid id);
    }
}