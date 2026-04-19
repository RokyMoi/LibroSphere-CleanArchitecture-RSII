using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    public class ShoppingCartItemConfiguration : IEntityTypeConfiguration<ShoppingCartItem>
    {
        public void Configure(EntityTypeBuilder<ShoppingCartItem> builder)
        {
            builder.ToTable("ShoppingCartItems");

            builder.HasKey(i => i.Id);

            builder.OwnsOne(i => i.Price, money =>
            {
                money.Property(m => m.amount)
                    .HasColumnName("PriceAmount")
                    .HasPrecision(18, 2)
                    .IsRequired();
                money.Property(m => m.Currency)
                     .HasConversion(
                         c => c.Code,
                         s => Currency.FromCode(s)
                     )
                     .HasColumnName("PriceCurrency")
                     .IsRequired();
            });

            builder.HasOne(i => i.Cart)
                   .WithMany(c => c.Items)
                   .HasForeignKey(i => i.CartId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(i => i.Book)
                   .WithMany(b => b.ShoppingCartItems)
                   .HasForeignKey(i => i.BookId)
                   .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
