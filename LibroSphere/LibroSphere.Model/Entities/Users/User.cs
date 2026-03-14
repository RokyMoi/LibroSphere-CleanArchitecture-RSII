using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.Users.Events;
using System;
using System.Collections.Generic;

namespace LibroSphere.Domain.Entities.Users
{
    public class User : BaseEntity
    {
        
        private User(
            Guid id,
            FirstName firstName,
            LastName lastName,
            Email email,
            Username username,
            string passwordHash,
            DateTime dateRegistered
        ) : base(id)
        {
            FirstName = firstName;
            LastName = lastName;
            Email = email;
            Username = username;
            PasswordHash = passwordHash;
            DateRegistered = dateRegistered;

            IsActive = true; 
            Reviews = new List<Review>();
            UserBooks = new List<UserBook>();
            Orders = new List<Order>();
        }

       
        public FirstName FirstName { get; private set; }
        public LastName LastName { get; private set; }
        public Username Username { get; private set; }
        public Email Email { get; private set; }
        public string PasswordHash { get; private set; }
        public DateTime DateRegistered { get; private set; }
        public DateTime? LastLogin { get; private set; }
        public bool IsActive { get; private set; }

        public ICollection<Review> Reviews { get; private set; }
        public ICollection<UserBook> UserBooks { get; private set; }
        public ICollection<Order> Orders { get; private set; }

        
        public static User Create(
            FirstName firstName,
            LastName lastName,
            Email email,
            Username username,
            string passwordHash
        )
        {
          var user=  new User(
                Guid.NewGuid(),
                firstName,
                lastName,
                email,
                username,
                passwordHash,
                DateTime.UtcNow
            );
      //We created domain event.. FOr Example is user is registered then maybe send him welcoming mail
            user.RaiseDomainEvent(new UserCreatedIDomainEvent(user.Id));
            return user;
        }

        
        public void Login()
        {
            LastLogin = DateTime.UtcNow;
        }

       
        public void Deactivate()
        {
            IsActive = false;
        }
    }
}