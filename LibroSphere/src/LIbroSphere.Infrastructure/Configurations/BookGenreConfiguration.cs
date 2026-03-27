using LibroSphere.Domain.Entities.ManyToMany;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    internal sealed class BookGenreConfiguration : IEntityTypeConfiguration<BookGenre>
    {
        public void Configure(EntityTypeBuilder<BookGenre> builder)
        {
            builder.ToTable("BookGenres");
            builder.HasKey(bg => bg.Id);

            builder.HasOne(bg => bg.Book)
                   .WithMany(b => b.BookGenres)
                   .HasForeignKey(bg => bg.BookId);

            builder.HasOne(bg => bg.Genre)
                   .WithMany(g => g.BookGenres)
                   .HasForeignKey(bg => bg.GenreId);
        }
    }
}