using LibroSphere.Domain.Entities.Authors;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LibroSphere.Infrastructure.Configurations
{
    internal sealed class AuthorConfiguration : IEntityTypeConfiguration<Author>
    {
        public void Configure(EntityTypeBuilder<Author> builder)
        {
            builder.ToTable("Author");

            builder.HasKey(author => author.Id);

            builder.Property(author => author.Name)
                .HasMaxLength(100)
                .HasConversion(name => name.Value, value => new Name(value));

            builder.Property(author => author.Biography)
                .HasMaxLength(4000)
                .HasConversion(bio => bio.Value, value => new Biography(value));

            builder.HasMany(author => author.Books)
                .WithOne(book => book.Author)
                .HasForeignKey(book => book.AuthorId);
        }
    }
}
