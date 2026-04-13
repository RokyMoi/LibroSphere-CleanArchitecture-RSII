using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.Reviews.Errors;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Application.Reviews.Command.CreateReview
{
    internal sealed class CreateReviewCommandHandler : ICommandHandler<CreateReviewCommand, Guid>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly IBookRepository _bookRepository;
        private readonly IUserRepository _userRepository;
        private readonly IUnitOfWork _unitOfWork;

        public CreateReviewCommandHandler(
            IReviewRepository reviewRepository,
            IBookRepository bookRepository,
            IUserRepository userRepository,
            IUnitOfWork unitOfWork)
        {
            _reviewRepository = reviewRepository;
            _bookRepository = bookRepository;
            _userRepository = userRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Result<Guid>> Handle(CreateReviewCommand request, CancellationToken cancellationToken)
        {
            var existing = await _reviewRepository.GetByUserAndBookAsync(request.UserId, request.BookId, cancellationToken);
            if (existing is not null)
            {
                return Result.Failure<Guid>(ReviewErrors.AlreadyExists);
            }

            var user = await _userRepository.GetAsyncById(request.UserId, cancellationToken);
            var book = await _bookRepository.GetAsyncById(request.BookId, cancellationToken);
            if (user is null || book is null)
            {
                return Result.Failure<Guid>(Error.NullValue);
            }

            var review = Review.Create(request.UserId, request.BookId, request.Rating, request.Comment);
            _reviewRepository.Add(review);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success(review.Id);
        }
    }
}
