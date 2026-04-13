namespace LibroSphere.Application.Common.Models;

public sealed record PagedResponse<T>(
    IReadOnlyList<T> Items,
    int Page,
    int PageSize,
    int TotalCount)
{
    public int TotalPages => TotalCount == 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
    public bool HasPreviousPage => Page > 1;
    public bool HasNextPage => Page < TotalPages;

    public static PagedResponse<T> Create(IEnumerable<T> source, int page, int pageSize)
    {
        var materialized = source.ToList();
        var totalCount = materialized.Count;
        var items = materialized
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return new PagedResponse<T>(items, page, pageSize, totalCount);
    }
}
