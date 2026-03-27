using LibroSphere.Domain.Entities.ShoppingCarts;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Domain.Entities.WishList;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

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

        

        builder.Property(u => u.DateRegistered);
        builder.Property(u => u.LastLogin);
        builder.Property(u => u.IsActive);

        builder.HasMany(u => u.Reviews)
               .WithOne(r => r.User)
               .HasForeignKey(r => r.UserId);

        builder.HasMany(u => u.UserBooks)
               .WithOne(ub => ub.User)
               .HasForeignKey(ub => ub.UserId);

        builder.HasMany(u => u.Orders)
               .WithOne(o => o.User)
               .HasForeignKey(o => o.UserId);

        builder.HasOne(u => u.ShoppingCart)
               .WithOne(c => c.User)
               .HasForeignKey<ShoppingCart>(c => c.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(u => u.Wishlist)
               .WithOne(c => c.User)
               .HasForeignKey<Wishlist>(c => c.UserId)
               .OnDelete(DeleteBehavior.Cascade);
    }
}