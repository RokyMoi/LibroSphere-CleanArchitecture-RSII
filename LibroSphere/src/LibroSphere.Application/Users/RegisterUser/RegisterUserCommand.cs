using LibroSphere.Application.Abstractions.Messaging;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace LibroSphere.Application.Users.RegisterUser
{
    public sealed record RegisterUserCommand(string Email,string FirstName,string LastName,string Password)
        : ICommand<Guid>;
    
  
}
