using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Infrastructure.Configurations
{
    internal sealed class BookConfiguration : IEntityTypeConfiguration<Book>
    {
        /// ZAPAMTTI: Kada imam value object sa vise polja, pisemo owns one da ne bi tretiralo kao novu tabelu
  
        public void Configure(EntityTypeBuilder<Book> builder)
        {
            builder.ToTable("Books");

            builder.HasKey(book => book.Id);


            builder.Property(book => book.Title)
                .HasMaxLength(200)
                .HasConversion(
                    title => title.Value,
                    value => new Title(value));


            builder.Property(book => book.Description)
                .HasMaxLength(200)
                .HasConversion(
                    description => description.Value,
                    value => new Description(value));


            builder.OwnsOne(book => book.Price, price =>
            {
                price.Property(p => p.amount)
                    .HasColumnName("Price");

                price.Property(p => p.Currency)
                    .HasConversion(
                        c => c.Code,
                        code => Currency.FromCode(code))
                    .HasColumnName("Currency");
            });


            builder.OwnsOne(book => book.BookLinkovi, links =>
            {
                links.Property(l => l.PdfLink)
                    .HasColumnName("PdfLink");

                links.Property(l => l.imageLink)
                    .HasColumnName("ImageLink");
            });


            builder.HasOne(book => book.Author)
              .WithMany(author => author.Books)
         .HasForeignKey(book => book.AuthorId);

            builder.HasMany(book => book.Reviews)
       .WithOne()
       .HasForeignKey("BookId");

            builder.HasMany(book => book.BookGenres)
       .WithOne(bg => bg.Book)
       .HasForeignKey("BookId");


            builder.HasMany(book => book.ShoppingCartItems)
       .WithOne(item => item.Book)  
       .HasForeignKey(item => item.BookId)
       .OnDelete(DeleteBehavior.Cascade);

            builder.HasMany(book => book.WishlistItems)
      .WithOne(item => item.Book)
     .HasForeignKey(item => item.BookId)
     .OnDelete(DeleteBehavior.Cascade);

            builder.HasMany(b => b.UserBooks)
       .WithOne(ub => ub.Book)
       .HasForeignKey(ub => ub.BookId);

        }
    }
}
