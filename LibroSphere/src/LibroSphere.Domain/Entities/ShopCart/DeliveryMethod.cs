using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.ShopCart
{
    internal class DeliveryMethod:BaseEntity
    {
        public required string ShortName { get; set; }
        public required string DeliveryTime { get; set; }
        public required string Description { get; set; }
        public Money Price { get; set; }

    }
}
