using LibroSphere.Domain.Entities.ManyToMany;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    internal class WishlistItemConfiguration : IEntityTypeConfiguration<WishlistItem>
    {
        public void Configure(EntityTypeBuilder<WishlistItem> builder)
        {
            builder.ToTable("WishlistItems");

            builder.HasKey(i => i.Id);

            builder.HasOne(i => i.Wishlist)
                   .WithMany(w => w.Items)
                   .HasForeignKey(i => i.WishlistId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(i => i.Book)
                   .WithMany(b => b.WishlistItems)
                   .HasForeignKey(i => i.BookId)
                   .OnDelete(DeleteBehavior.Cascade);
        }
    }
}