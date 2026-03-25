using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Authors;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Authors.Query.GetAuthorById
{
  public sealed record GetAuthorByIdQuery(Guid autorId):IQuery<AuthorResponse>;
}
