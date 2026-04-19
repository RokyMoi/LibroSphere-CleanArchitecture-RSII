
using LibroSphere.Domain.Entities.Users;
using Microsoft.AspNetCore.Identity;

public class ApplicationUser : IdentityUser
{
 
    public Guid DomainUserId { get; set; }


    public User DomainUser { get; set; } = null!;


    public DateTime DateRegistered { get; set; }


    public string? RefreshToken { get; set; }
    public DateTime? RefreshTokenExpiry { get; set; }
}
