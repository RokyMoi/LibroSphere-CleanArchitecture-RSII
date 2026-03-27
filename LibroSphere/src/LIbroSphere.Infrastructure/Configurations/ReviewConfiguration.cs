using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Reviews;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Infrastructure.Configurations
{
    public class ReviewConfiguration : IEntityTypeConfiguration<Review>
    {
        public void Configure(EntityTypeBuilder<Review> builder)
        {
            builder.ToTable("Review");

            builder.HasKey(r => r.Id);

            // FK na Book
            builder.HasOne(r => r.Book)
                   .WithMany(b => b.Reviews)
                   .HasForeignKey(r => r.BookId)
                   // OnDelete Cascade samo za ovaj FK
                   .OnDelete(DeleteBehavior.Cascade);

            // FK na User
            builder.HasOne(r => r.User)
                   .WithMany(u => u.Reviews)
                   .HasForeignKey(r => r.UserId)
                   // Obično je NoAction, da brisanje usera ne briše sve review-e automatski
                   .OnDelete(DeleteBehavior.NoAction);

            // Properties
            builder.Property(r => r.Rating)
                   .IsRequired();

            builder.Property(r => r.Comment)
                   .IsRequired();

            builder.Property(r => r.CreatedAt)
                   .IsRequired();
        }
    }
}
