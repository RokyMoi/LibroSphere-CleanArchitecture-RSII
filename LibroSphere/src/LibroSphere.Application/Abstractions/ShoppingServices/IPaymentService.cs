using LibroSphere.Domain.Entities.ShopCart;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.ShoppingServices
{
    public interface IPaymentService
    {
        Task<ShoppingCart> CreateOrUpdatePaymentIntent(string cartId);
    }
}
