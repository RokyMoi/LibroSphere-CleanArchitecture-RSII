namespace LibroSphere.WebApi.Controllers.Users
{
    public sealed record RegisterUserRequest(string Email,string password,string LastName,string FirstName);
    
}
