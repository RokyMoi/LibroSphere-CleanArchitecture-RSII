using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Users;
using System;

namespace LibroSphere.Domain.Entities.Recommended
{
    public class RecommendedBook : BaseEntity
    {
        private RecommendedBook(
            Guid id,
            Guid userId,
            Guid bookId,
            double score,
            string reason,
            DateTime createdAt) : base(id)
        {
            UserId = userId;
            BookId = bookId;
            Score = score;
            Reason = reason;
            CreatedAt = createdAt;
        }
        protected RecommendedBook() { }
        public Guid UserId { get; private set; }
        public User User { get; private set; }

        public Guid BookId { get; private set; }
        public Book Book { get; private set; }

        public double Score { get; private set; }

        public string Reason { get; private set; }

        public DateTime CreatedAt { get; private set; }

        // Factory Method
        public static RecommendedBook MakeRecommendation(
            Guid userId,
            Guid bookId,
            double score,
            string reason)
        {
            return new RecommendedBook(
                Guid.NewGuid(),
                userId,
                bookId,
                score,
                reason,
                DateTime.UtcNow
            );
        }
    }
}