using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.Recommended;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.ShoppingCarts;
using LibroSphere.Domain.Entities.Users.Events;
using LibroSphere.Domain.Entities.WishList;
using System;
using System.Collections.Generic;
using LibroSphere.Domain.Abstractions.Clock;

namespace LibroSphere.Domain.Entities.Users
{
    public class User : BaseEntity
    {
        private User(
            Guid id,
            FirstName firstName,
            LastName lastName,
            Email email
          
        ) : base(id)
        {
            FirstName = firstName;
            LastName = lastName;
            UserEmail = email;
     

            IsActive = true;
            Reviews = new List<Review>();
            UserBooks = new List<UserBook>();
            Orders = new List<Order>();
        }

        protected User() { }

        public FirstName FirstName { get; private set; }
        public LastName LastName { get; private set; }
        public Username Username { get; private set; }
        public Email UserEmail { get; private set; }
        public string PasswordHash { get; private set; }
        public DateTime DateRegistered { get; private set; }
        public DateTime? LastLogin { get; private set; }
        public bool IsActive { get; private set; }

        public ICollection<Review> Reviews { get; private set; }
        public ICollection<UserBook> UserBooks { get; private set; }
        public ICollection<Order> Orders { get; private set; }
        public ShoppingCart ShoppingCart { get; private set; }
        public Wishlist Wishlist { get; private set; }
        public ICollection<RecommendedBook> RecommendedBooks { get; private set; }
        public string IdentityId { get; private set; } = string.Empty;

        
        public static User Create(
            FirstName firstName,
            LastName lastName,
            Email email
         
           
        )
        {
            var user = new User(
                Guid.NewGuid(),
                firstName,
                lastName,
                email
            
            );

            user.RaiseDomainEvent(new UserCreatedIDomainEvent(user.Id));
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

        public void SetIdentityId(string identityId)
        {
            IdentityId = identityId;
        }
    }
}