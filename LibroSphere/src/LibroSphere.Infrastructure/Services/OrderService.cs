using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Abstraction;
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

        public async Task<Result<Order>> CreateOrderAsync(
            string buyerEmail,
            Guid userId,
            string cartId,
            string paymentIntentId)
        {
            var existingOrder = await _orderRepo.GetByPaymentIntentIdAsync(paymentIntentId);
            if (existingOrder is not null)
            {
                return existingOrder.UserId == userId
                    ? Result.Success(existingOrder)
                    : Result.Failure<Order>(new Error("Order.Cart.Forbidden", "You do not have access to this order."));
            }

            var cart = await _cartService.GetCartASync(cartId);
            if (cart == null)
            {
                return Result.Failure<Order>(new Error("Order.Cart.NotFound", "Cart not found."));
            }

            if (cart.UserId != userId)
            {
                return Result.Failure<Order>(new Error("Order.Cart.Forbidden", "You do not have access to this cart."));
            }

            if (string.IsNullOrEmpty(cart.PaymentIntentId))
            {
                return Result.Failure<Order>(new Error("Order.PaymentIntent.Missing", "No payment intent. Call /api/payment/{cartId} first."));
            }

            if (!string.Equals(cart.PaymentIntentId, paymentIntentId, StringComparison.Ordinal))
            {
                return Result.Failure<Order>(new Error("Order.PaymentIntent.Mismatch", "Payment intent does not match the cart."));
            }

            var bookIds = cart.Items.Select(i => i.BookId).Distinct().ToList();
            var books = await _bookRepo.GetByIdsWithDetailsAsync(bookIds, CancellationToken.None);
            var bookLookup = books.ToDictionary(b => b.Id);

            var orderItems = new List<OrderItem>();
            foreach (var item in cart.Items)
            {
                if (!bookLookup.TryGetValue(item.BookId, out var book))
                {
                    return Result.Failure<Order>(new Error("Order.Book.NotFound", $"Book {item.BookId} not found."));
                }

                orderItems.Add(OrderItem.Create(
                    book.Id,
                    book.Title.Value,
                    book.BookLinkovi.imageLink,
                    book.Price,
                    quantity: 1));
            }

            var order = Order.Create(
                userId,
                buyerEmail,
                orderItems,
                cart.PaymentIntentId,
                cart.ClientSecret!);

            await _orderRepo.AddAsync(order);
            await _orderRepo.SaveChangesAsync();

            return Result.Success(order);
        }

        public async Task<List<Order>> GetOrdersForUserAsync(Guid userId)
            => await _orderRepo.GetByUserIdAsync(userId);

        public async Task<List<Order>> GetAllOrdersAsync(CancellationToken cancellationToken = default)
            => await _orderRepo.GetAllAsync();

        public async Task<Order?> GetOrderByIdAsync(Guid id)
            => await _orderRepo.GetByIdAsync(id);

        public async Task SaveChangesAsync(CancellationToken cancellationToken = default)
            => await _orderRepo.SaveChangesAsync();
    }
}
