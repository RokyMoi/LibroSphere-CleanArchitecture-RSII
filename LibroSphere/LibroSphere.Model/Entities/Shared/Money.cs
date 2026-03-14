using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Shared
{
    public record Money(decimal amount,Currency Currency )
    {
        public static Money operator +(Money first, Money second) {
            if (first.Currency != second.Currency) {
                throw new InvalidOperationException("Currencies need to be equal");
            }
            else
            {
                return new Money(first.amount + second.amount, first.Currency);
            }
        }

        public static Money Zero() => new(0,Currency.None);
    }
}
