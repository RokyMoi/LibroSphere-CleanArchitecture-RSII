using FluentValidation;

namespace LibroSphere.Application.Orders.Query.GetOrderById
{
    public sealed class GetOrderByIdQueryValidator : AbstractValidator<GetOrderByIdQuery>
    {
        public GetOrderByIdQueryValidator()
        {
            RuleFor(x => x.OrderId).NotEmpty();
        }
    }
}
