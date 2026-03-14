using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Users;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.Recommended
{
    public class RecommendedBook:BaseEntity
    {
        public RecommendedBook(Guid id) : base(id)
        {

        }

        public Guid UserId { get; private set; }
        public User User { get; private set; }

        public Guid BookId { get; private set; }
        public Book Book { get; private set; }

        public double Score { get; private set; }

        public string Reason { get; private set; }

        public DateTime CreatedAt { get; private set; }
    }
}
