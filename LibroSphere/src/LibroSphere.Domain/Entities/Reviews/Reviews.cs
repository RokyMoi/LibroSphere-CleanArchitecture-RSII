using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Reviews.Events;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Domain.Entities.Reviews
{
    public class Review : BaseEntity
    {
        private Review(
            Guid id,
            Guid userId,
            Guid bookId,
            int rating,
            string comment,
            DateTime createdAt) : base(id)
        {
            UserId = userId;
            BookId = bookId;
            Rating = rating;
            Comment = comment;
            CreatedAt = createdAt;
        }

        protected Review()
        {
        }

        public Guid UserId { get; private set; }
        public User User { get; private set; } = null!;
        public Guid BookId { get; private set; }
        public Book Book { get; private set; } = null!;
        public int Rating { get; private set; }
        public string Comment { get; private set; } = string.Empty;
        public DateTime CreatedAt { get; private set; }

        public static Review Create(Guid userId, Guid bookId, int rating, string comment)
        {
            EnsureValidRating(rating);
            var review = new Review(Guid.NewGuid(), userId, bookId, rating, comment, DateTime.UtcNow);
            review.RaiseDomainEvent(new ReviewCreatedDomainEvent(review.Id, review.UserId, review.BookId, review.Rating));
            return review;
        }

        public void Update(int rating, string comment)
        {
            EnsureValidRating(rating);
            Rating = rating;
            Comment = comment;
            RaiseDomainEvent(new ReviewUpdatedDomainEvent(Id, UserId, BookId, Rating));
        }

        private static void EnsureValidRating(int rating)
        {
            if (rating < 1 || rating > 5)
            {
                throw new InvalidOperationException($"Rating must be between 1 and 5. Got: {rating}.");
            }
        }

        public void MarkAsDeleted()
        {
            RaiseDomainEvent(new ReviewDeletedDomainEvent(Id, UserId, BookId));
        }
    }
}
