using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Infrastructure.Services
{
    public class OrderService : IOrderService
    {
        private readonly IOrderRepository _orderRepo;
        private readonly ICartService _cartService;
        private readonly IBookRepository _bookRepo;

        public OrderService(
            IOrderRepository orderRepo,
            ICartService cartService,
            IBookRepository bookRepo)
        {
            _orderRepo = orderRepo;
            _cartService = cartService;
            _bookRepo = bookRepo;
        }

        public async Task<Order> CreateOrderAsync(string buyerEmail, string cartId)
        {
            var cart = await _cartService.GetCartASync(cartId);
            if (cart == null)
                throw new Exception("Cart not found");

            if (string.IsNullOrEmpty(cart.PaymentIntentId))
                throw new Exception("No payment intent. Call /api/payment/{cartId} first.");

            var orderItems = new List<OrderItem>();

            foreach (var item in cart.Items)
            {
                var book = await _bookRepo.GetAsyncById(item.BookId);
                if (book == null)
                    throw new Exception($"Book {item.BookId} not found");

                orderItems.Add(OrderItem.Create(
                    book.Id,
                    book.Title.Value,
                    book.BookLinkovi.imageLink,
                    book.Price,
                    quantity: 1  
                ));
            }

            var order = Order.Create(
                buyerEmail,
                orderItems,
                cart.PaymentIntentId,
                cart.ClientSecret!
            );

            await _orderRepo.AddAsync(order);
            await _orderRepo.SaveChangesAsync();

         
            await _cartService.DeleteCartAsync(cartId);

            return order;
        }

        public async Task<List<Order>> GetOrdersForUserAsync(string email)
            => await _orderRepo.GetByEmailAsync(email);

        public async Task<Order?> GetOrderByIdAsync(Guid id)
            => await _orderRepo.GetByIdAsync(id);
    }
}