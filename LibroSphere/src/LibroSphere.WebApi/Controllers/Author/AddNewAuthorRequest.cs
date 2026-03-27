using System.Security.Principal;

namespace LibroSphere.WebApi.Controllers.Author
{
    public class AddNewAuthorRequest
    {
        public string Name { get; set; }
        public string Biography { get; set; }
    }
}
