using LibroSphere.Domain.Entities.Books.Genre;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    internal sealed class GenreConfiguration : IEntityTypeConfiguration<Genre>
    {
        public void Configure(EntityTypeBuilder<Genre> builder)
        {
            builder.ToTable("Genres");
            builder.HasKey(g => g.Id);

            builder.Property(g => g.Name)
                .HasMaxLength(50)
                .HasConversion(n => n.Value, value => new Name(value));

            builder.HasIndex(g => g.Name).IsUnique();

            builder.HasMany(g => g.BookGenres)
                .WithOne(bg => bg.Genre)
                .HasForeignKey(bg => bg.GenreId);
        }
    }
}
