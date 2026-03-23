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

          
            builder.OwnsOne(o => o.TotalPrice, money =>
            {
                money.Property(m => m.amount).HasColumnName("TotalPriceAmount").IsRequired();
                money.Property(m => m.Currency)
                     .HasConversion(
                         c => c.Code,          
                         s => Currency.FromCode(s) 
                     )
                     .HasColumnName("TotalPriceCurrency")
                     .IsRequired();
            });

            builder.Property(o => o.PaymentStatus)
                   .HasConversion<int>()
                   .IsRequired();

            builder.Property(o => o.CreatedAt)
                   .IsRequired();

            builder.HasOne(o => o.User)
                   .WithMany(u => u.Orders)
                   .HasForeignKey(o => o.UserId)
                   .OnDelete(DeleteBehavior.Cascade);

          
        }
    }
}