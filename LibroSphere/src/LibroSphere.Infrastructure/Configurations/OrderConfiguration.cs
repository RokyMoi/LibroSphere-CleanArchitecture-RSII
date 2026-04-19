using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    public class OrderConfiguration : IEntityTypeConfiguration<Order>
    {
        public void Configure(EntityTypeBuilder<Order> builder)
        {
            builder.ToTable("Orders");
            builder.HasKey(o => o.Id);

            builder.Property(o => o.BuyerEmail)
                .HasMaxLength(256)
                .IsRequired();

            builder.Property(o => o.OrderDate)
                .IsRequired();

            builder.Property(o => o.Status)
                .HasConversion<int>()
                .IsRequired();

            builder.Property(o => o.PaymentIntentId)
                .HasMaxLength(200)
                .IsRequired();

            builder.Property(o => o.ClientSecret)
                .HasMaxLength(500);

            builder.OwnsOne(o => o.TotalAmount, money =>
            {
                money.Property(m => m.amount)
                    .HasColumnName("TotalAmount")
                    .HasPrecision(18, 2)
                    .IsRequired();

                money.Property(m => m.Currency)
                    .HasConversion(c => c.Code, s => Currency.FromCode(s))
                    .HasColumnName("TotalCurrency")
                    .IsRequired();
            });

            builder.HasMany(o => o.Items)
                .WithOne()
                .HasForeignKey("OrderId")
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
