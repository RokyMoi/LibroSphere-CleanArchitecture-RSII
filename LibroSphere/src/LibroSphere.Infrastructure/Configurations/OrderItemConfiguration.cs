using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    public class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
    {
        public void Configure(EntityTypeBuilder<OrderItem> builder)
        {
            builder.ToTable("OrderItems");
            builder.HasKey(oi => oi.Id);

            builder.Property(oi => oi.BookId).IsRequired();
            builder.Property(oi => oi.Title).HasMaxLength(250).IsRequired();
            builder.Property(oi => oi.ImageLink).HasMaxLength(1000);
            builder.Property(oi => oi.Quantity).IsRequired();

            builder.OwnsOne(oi => oi.Price, money =>
            {
                money.Property(m => m.amount)
                    .HasColumnName("PriceAmount")
                    .HasPrecision(18, 2)
                    .IsRequired();

                money.Property(m => m.Currency)
                    .HasConversion(c => c.Code, s => Currency.FromCode(s))
                    .HasColumnName("PriceCurrency")
                    .IsRequired();
            });
        }
    }
}
