using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Abstractions.Clock;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.Recommended;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.ShopCart;
using LibroSphere.Domain.Entities.Users.Events;
using LibroSphere.Domain.Entities.WishList;

namespace LibroSphere.Domain.Entities.Users
{
    public class User : BaseEntity
    {
        private User(
            Guid id,
            FirstName firstName,
            LastName lastName,
            Email email,
            DateTime dateRegistered
        ) : base(id)
        {
            FirstName = firstName;
            LastName = lastName;
            UserEmail = email;
            DateRegistered = dateRegistered;
            IsActive = true;
            Reviews = new List<Review>();
            UserBooks = new List<UserBook>();
            Orders = new List<Order>();
        }

        protected User() { }

        public FirstName FirstName { get; private set; }
        public LastName LastName { get; private set; }
        public Email UserEmail { get; private set; }

        // PasswordHash i Username su uklonjeni — Identity ih čuva

        public DateTime DateRegistered { get; private set; }
        public DateTime? LastLogin { get; private set; }
        public bool IsActive { get; private set; }

        public ICollection<Review> Reviews { get; private set; }
        public ICollection<UserBook> UserBooks { get; private set; }
        public ICollection<Order> Orders { get; private set; }
        public ShoppingCart ShoppingCart { get; private set; }
        public Wishlist Wishlist { get; private set; }
        public ICollection<RecommendedBook> RecommendedBooks { get; private set; }

        public static User Create(
            FirstName firstName,
            LastName lastName,
            Email email,
            IDateTimeProvider dateTimeProvider
        )
        {
            var user = new User(
                Guid.NewGuid(),
                firstName,
                lastName,
                email,
                dateTimeProvider.UtcNow
            );

            user.RaiseDomainEvent(new UserCreatedDomainEvent(user.Id,user.UserEmail.Value));
            return user;
        }

        public void Login(IDateTimeProvider dateTimeProvider)
        {
            LastLogin = dateTimeProvider.UtcNow;
        }

        public void Deactivate()
        {
            IsActive = false;
        }
    }
}