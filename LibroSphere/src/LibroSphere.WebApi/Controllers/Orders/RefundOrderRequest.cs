namespace LibroSphere.WebApi.Controllers.Orders;

public sealed record RefundOrderRequest(
    decimal? Amount,
    string? Reason);
