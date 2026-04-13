using FluentValidation;

namespace LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;

public sealed class GetAnalyticsOverviewQueryValidator : AbstractValidator<GetAnalyticsOverviewQuery>
{
    public GetAnalyticsOverviewQueryValidator()
    {
        RuleFor(x => x.RecentActivityTake).InclusiveBetween(1, 50);
    }
}
