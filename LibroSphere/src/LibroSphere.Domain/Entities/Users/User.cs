using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Abstractions.Clock;
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
            DateTime dateRegistered) : base(id)
        {
            FirstName = firstName;
            LastName = lastName;
            UserEmail = email;
            DateRegistered = dateRegistered;
            IsActive = true;
            Reviews = new List<Review>();
        }

        protected User()
        {
            Reviews = new List<Review>();
        }

        public FirstName FirstName { get; private set; } = null!;
        public LastName LastName { get; private set; } = null!;
        public Email UserEmail { get; private set; } = null!;
        public DateTime DateRegistered { get; private set; }
        public DateTime? LastLogin { get; private set; }
        public bool IsActive { get; private set; }
        public ICollection<Review> Reviews { get; private set; }
        public ShoppingCart? ShoppingCart { get; private set; }
        public Wishlist? Wishlist { get; private set; }

        public static User Create(
            FirstName firstName,
            LastName lastName,
            Email email,
            IDateTimeProvider dateTimeProvider)
        {
            return new User(
                Guid.NewGuid(),
                firstName,
                lastName,
                email,
                dateTimeProvider.UtcNow);
        }

        public void Login(IDateTimeProvider dateTimeProvider)
        {
            LastLogin = dateTimeProvider.UtcNow;
            RaiseDomainEvent(new UserLoggedInDomainEvent(Id, UserEmail.Value));
        }

        public void Deactivate()
        {
            IsActive = false;
            RaiseDomainEvent(new UserDeactivatedDomainEvent(Id, UserEmail.Value));
        }
    }
}
