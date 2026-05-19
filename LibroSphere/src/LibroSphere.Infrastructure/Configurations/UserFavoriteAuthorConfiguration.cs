using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    internal sealed class UserFavoriteAuthorConfiguration : IEntityTypeConfiguration<UserFavoriteAuthor>
    {
        public void Configure(EntityTypeBuilder<UserFavoriteAuthor> builder)
        {
            builder.ToTable("UserFavoriteAuthors");

            builder.HasKey(ufa => new { ufa.UserId, ufa.AuthorId });

            builder.HasOne<User>()
                .WithMany(u => u.FavoriteAuthors)
                .HasForeignKey(ufa => ufa.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne<Author>()
                .WithMany()
                .HasForeignKey(ufa => ufa.AuthorId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
