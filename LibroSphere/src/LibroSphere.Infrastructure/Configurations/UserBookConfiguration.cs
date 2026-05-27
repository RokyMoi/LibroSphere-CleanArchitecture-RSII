using LibroSphere.Domain.Entities.ManyToMany;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    public class UserBookConfiguration : IEntityTypeConfiguration<UserBook>
    {
        public void Configure(EntityTypeBuilder<UserBook> builder)
        {
            builder.ToTable("UserBooks");
            builder.HasKey(ub => ub.Id);

            builder.Property(ub => ub.UserId)
                .IsRequired();

            builder.Property(ub => ub.PurchasedAt)
                .IsRequired();

            builder.HasOne(ub => ub.Book)
                .WithMany(b => b.UserBooks)
                .HasForeignKey(ub => ub.BookId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(ub => ub.User)
                .WithMany()
                .HasForeignKey(ub => ub.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(ub => new { ub.UserId, ub.BookId }).IsUnique();
        }
    }
}
