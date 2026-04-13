using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;

namespace LibroSphere.Application.Library.Query.GetMyLibrary
{
    public sealed record GetMyLibraryQuery(
        string Email,
        string? SearchTerm = null,
        int Page = 1,
        int PageSize = 12) : IQuery<PagedResponse<LibraryBookResponse>>;
}
