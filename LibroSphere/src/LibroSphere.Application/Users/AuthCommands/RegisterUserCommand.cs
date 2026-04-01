using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Messaging;
using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace LibroSphere.Application.Users.AuthCommands
{
    public record RegisterUserCommand(
    string FirstName,
    string LastName,
    string Email,
    string Password
) : ICommand<AuthResult>;
}
