using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Authors.Command.CreateNewAuthor
{
    public  record MakeANewAuthorCommand(Name name,
          Biography Biography ) : ICommand<Guid>;
}
