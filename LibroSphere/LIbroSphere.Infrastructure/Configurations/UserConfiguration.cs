using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LibroSphere.Domain.Entities.Users;

namespace LIbroSphere.Infrastructure.Configurations
{
    internal sealed class UserConfiguration : IEntityTypeConfiguration<User>
    {
        public void Configure(EntityTypeBuilder<User> builder)
        {
            builder.ToTable("Users");

            builder.HasKey(u => u.Id);

            // Value Objects
            builder.Property(u => u.FirstName)
                   .HasMaxLength(100)
                   .HasConversion(fn => fn.Value, value => new FirstName(value));

            builder.Property(u => u.LastName)
                   .HasMaxLength(100)
                   .HasConversion(ln => ln.Value, value => new LastName(value));

            builder.Property(u => u.Username)
                   .HasMaxLength(50)
                   .HasConversion(un => un.Value, value => new Username(value));

            builder.Property(u => u.Email)
                   .HasMaxLength(150)
                   .HasConversion(em => em.Value, value => new LibroSphere.Domain.Entities.Users.Email(value);

            //Dodati mozda Has Index za Username i Email da su UNIQUE!
          
            builder.Property(u => u.PasswordHash)
                   .HasMaxLength(300);

           
            builder.Property(u => u.DateRegistered);
            builder.Property(u => u.LastLogin);

         
            builder.Property(u => u.IsActive);


          
            builder.HasMany(u => u.Reviews)
                   .WithOne(r => r.User)
                   .HasForeignKey(r => r.UserId);

         
            builder.HasMany(u => u.UserBooks)
                .WithOne(ub => ub.User)
                 .HasForeignKey(ub => ub.UserId);

            builder.HasMany(u => u.Orders)
                 .WithOne(o => o.User)
                  .HasForeignKey(o => o.UserId);
        }
    }
}