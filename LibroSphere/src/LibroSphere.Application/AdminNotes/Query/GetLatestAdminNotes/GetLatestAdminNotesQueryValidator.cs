using FluentValidation;

namespace LibroSphere.Application.AdminNotes.Query.GetLatestAdminNotes;

public sealed class GetLatestAdminNotesQueryValidator : AbstractValidator<GetLatestAdminNotesQuery>
{
    public GetLatestAdminNotesQueryValidator()
    {
        RuleFor(x => x.Take)
            .InclusiveBetween(1, 100);
    }
}
