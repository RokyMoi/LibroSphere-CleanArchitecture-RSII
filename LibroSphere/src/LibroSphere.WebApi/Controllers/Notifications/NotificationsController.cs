using LibroSphere.Application.Notifications.Command.MarkAllNotificationsRead;
using LibroSphere.Application.Notifications.Command.MarkNotificationRead;
using LibroSphere.Application.Notifications.Query.GetNotifications;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Notifications;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class NotificationsController : ControllerBase
{
    private readonly ISender _sender;

    public NotificationsController(ISender sender)
    {
        _sender = sender;
    }

    [HttpGet]
    public async Task<IActionResult> GetNotifications(
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        var result = await _sender.Send(
            new GetNotificationsQuery(User.GetRequiredUserId(), User.GetRequiredEmail(), take),
            cancellationToken);

        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    [HttpPost("{id}/read")]
    public async Task<IActionResult> MarkAsRead(string id, CancellationToken cancellationToken = default)
    {
        var result = await _sender.Send(
            new MarkNotificationReadCommand(User.GetRequiredUserId(), id),
            cancellationToken);

        return result.IsSuccess
            ? Ok(new { message = "Notification marked as read." })
            : BadRequest(result.Error);
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllAsRead(
        [FromQuery] int take = 100,
        CancellationToken cancellationToken = default)
    {
        var result = await _sender.Send(
            new MarkAllNotificationsReadCommand(User.GetRequiredUserId(), User.GetRequiredEmail(), take),
            cancellationToken);

        return result.IsSuccess
            ? Ok(new { message = "All visible notifications are marked as read." })
            : BadRequest(result.Error);
    }
}
