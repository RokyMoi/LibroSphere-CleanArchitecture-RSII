using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Infrastructure.Configurations
{

    internal sealed class ApplicationUserConfiguration
        : IEntityTypeConfiguration<ApplicationUser>
    {
        public void Configure(EntityTypeBuilder<ApplicationUser> builder)
        {
            // Identity već kreira svoju tabelu (AspNetUsers)
       

            builder.Property(au => au.DomainUserId)
                   .IsRequired();

            builder.Property(au => au.DateRegistered)
                   .IsRequired();

            builder.Property(au => au.RefreshToken)
                   .HasMaxLength(500);

            builder.Property(au => au.RefreshTokenExpiry);

     
            builder.HasOne(au => au.DomainUser)
                   .WithOne()
                   .HasForeignKey<ApplicationUser>(au => au.DomainUserId)
                   .OnDelete(DeleteBehavior.Cascade);

           
            builder.HasIndex(au => au.DomainUserId)
                   .IsUnique();
        }
    }
}
