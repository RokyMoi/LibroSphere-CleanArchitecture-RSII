using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Recommendations;
using LibroSphere.Domain.Entities.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    internal sealed class CartInteractionConfiguration : IEntityTypeConfiguration<CartInteraction>
    {
        public void Configure(EntityTypeBuilder<CartInteraction> builder)
        {
            builder.ToTable("CartInteractions");

            builder.HasKey(ci => new { ci.UserId, ci.BookId });

            builder.Property(ci => ci.LastAddedAt).IsRequired();

            // Index used by the recommender's per-book cart popularity aggregate (CartStats).
            builder.HasIndex(ci => ci.BookId);

            builder.HasOne<User>()
                .WithMany()
                .HasForeignKey(ci => ci.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne<Book>()
                .WithMany()
                .HasForeignKey(ci => ci.BookId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
