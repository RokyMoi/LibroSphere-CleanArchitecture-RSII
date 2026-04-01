using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Entities.ShopCart;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Infrastructure.Services
{
    public class PaymentService : IPaymentService
    {
        public Task<ShoppingCart> CreateOrUpdatePaymentIntent(string cartId)
        {
            throw new NotImplementedException();
        }
    }
}
