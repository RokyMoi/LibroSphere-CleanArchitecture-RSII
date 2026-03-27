using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Authors.Query.GetAuthorById
{
    public sealed class AuthorResponse
    {
        public Guid id {  get; init; }
        public object Id { get; internal set; }
        public string Name { get; init; }
        public string Biography { get; init; }
    }
}
