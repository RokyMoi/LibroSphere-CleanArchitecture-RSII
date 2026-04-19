using LibroSphere.Domain.Entities.ShopCart;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Domain.Entities.WishList;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    internal sealed class UserConfiguration : IEntityTypeConfiguration<User>
    {
        public void Configure(EntityTypeBuilder<User> builder)
        {
            builder.ToTable("Users");
            builder.HasKey(u => u.Id);

            builder.Property(u => u.FirstName)
                .HasMaxLength(100)
                .HasConversion(fn => fn.Value, value => new FirstName(value));

            builder.Property(u => u.LastName)
                .HasMaxLength(100)
                .HasConversion(ln => ln.Value, value => new LastName(value));

            builder.Property(u => u.UserEmail)
                .HasMaxLength(150)
                .HasConversion(em => em.Value, value => new Email(value));

            builder.Property(u => u.DateRegistered).IsRequired();
            builder.Property(u => u.LastLogin);
            builder.Property(u => u.IsActive).IsRequired();

            builder.HasIndex(u => u.UserEmail).IsUnique();

            builder.HasMany(u => u.Reviews)
                .WithOne(r => r.User)
                .HasForeignKey(r => r.UserId);

            builder.HasOne(u => u.ShoppingCart)
                .WithOne(c => c.User)
                .HasForeignKey<ShoppingCart>(c => c.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(u => u.Wishlist)
                .WithOne(w => w.User)
                .HasForeignKey<Wishlist>(w => w.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
