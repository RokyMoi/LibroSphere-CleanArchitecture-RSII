using System.Security.Principal;

namespace LibroSphere.WebApi.Controllers.Requests
{
    public class AddNewAuthorRequest
    {
        public string Name { get; set; }
        public string Biography { get; set; }
    }
}
