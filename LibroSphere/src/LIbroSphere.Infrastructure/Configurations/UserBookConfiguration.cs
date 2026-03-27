using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Infrastructure.Configurations
{
    using global::LibroSphere.Domain.Entities.ManyToMany;
   
    using Microsoft.EntityFrameworkCore;
    using Microsoft.EntityFrameworkCore.Metadata.Builders;

    namespace LibroSphere.Infrastructure.Persistence.Configurations
    {
        public class UserBookConfiguration : IEntityTypeConfiguration<UserBook>
        {
            public void Configure(EntityTypeBuilder<UserBook> builder)
            {
                
                builder.HasKey(ub => ub.Id);

            
                builder.HasOne(ub => ub.User)
                       .WithMany(u => u.UserBooks) 
                       .HasForeignKey(ub => ub.UserId)
                       .OnDelete(DeleteBehavior.Cascade);

                builder.HasOne(ub => ub.Book)
                       .WithMany(b => b.UserBooks) 
                       .HasForeignKey(ub => ub.BookId)
                       .OnDelete(DeleteBehavior.Cascade);

            
                builder.Property(ub => ub.Status)
                       .HasConversion<int>() 
                       .IsRequired();

             
                builder.Property(ub => ub.AddedAt)
                       .IsRequired();

               
                builder.ToTable("UserBooks");
            }
        }
    }
}
