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
    public record RefreshTokenCommand(
       string RefreshToken
   ) : ICommand<AuthResult>;
}
