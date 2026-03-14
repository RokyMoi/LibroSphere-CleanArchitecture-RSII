using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Users;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class UserBook:BaseEntity
    {
        public UserBook(Guid id) : base(id)
        {

        }
       

      

        public Guid UserId { get; private set; }
        public User User { get; private set; }

        public Guid BookId { get; private set; }
        public Book Book { get; private set; }

        public string Status { get; private set; }

        public DateTime AddedAt { get; private  set; }
    }
}
