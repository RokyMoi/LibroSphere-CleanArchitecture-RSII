
using LibroSphere.Domain.Entities.ShopCart;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    public class ShoppingCartConfiguration : IEntityTypeConfiguration<ShoppingCart>
    {
        public void Configure(EntityTypeBuilder<ShoppingCart> builder)
        {
            builder.ToTable("ShoppingCarts");

            builder.HasKey(c => c.Id);

            builder.HasOne(c => c.User)
                   .WithOne(u => u.ShoppingCart)  
                   .HasForeignKey<ShoppingCart>(c => c.UserId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasMany(c => c.Items)
                   .WithOne(i => i.Cart)
                   .HasForeignKey(i => i.CartId)
                   .OnDelete(DeleteBehavior.Cascade);
        }
    }
}