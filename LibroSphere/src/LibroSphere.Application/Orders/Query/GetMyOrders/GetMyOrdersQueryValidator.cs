using FluentValidation;

namespace LibroSphere.Application.Orders.Query.GetMyOrders
{
    public sealed class GetMyOrdersQueryValidator : AbstractValidator<GetMyOrdersQuery>
    {
        public GetMyOrdersQueryValidator()
        {
            RuleFor(x => x.BuyerEmail).NotEmpty().EmailAddress();
            RuleFor(x => x.Page).GreaterThanOrEqualTo(1);
            RuleFor(x => x.PageSize).InclusiveBetween(1, 100);
        }
    }
}
