using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.AdminNotes.Command.CreateAdminNote;
using LibroSphere.Application.AdminNotes.Command.DeleteAdminNote;
using LibroSphere.Application.AdminNotes.Query.GetLatestAdminNotes;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.AdminNotes;

[ApiController]
[Route("api/adminnotes")]
[Authorize]
public sealed class AdminNotesController : ControllerBase
{
    private readonly ISender _sender;
    private readonly IBookAssetStorageService _storageService;
    private const long MaxImageBytes = 10 * 1024 * 1024;
    private static readonly HashSet<string> AllowedImageContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp"
    };

    public AdminNotesController(ISender sender, IBookAssetStorageService storageService)
    {
        _sender = sender;
        _storageService = storageService;
    }

    [HttpGet]
    public async Task<IActionResult> GetLatest(
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        var result = await _sender.Send(new GetLatestAdminNotesQuery(take), cancellationToken);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    [Authorize(Roles = ApplicationRoles.Admin)]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateAdminNoteRequest request,
        CancellationToken cancellationToken = default)
    {
        var result = await _sender.Send(
            new CreateAdminNoteCommand(request.Title, request.Text, request.ImageUrl),
            cancellationToken);

        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    [Authorize(Roles = ApplicationRoles.Admin)]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken = default)
    {
        var result = await _sender.Send(new DeleteAdminNoteCommand(id), cancellationToken);
        return result.IsSuccess ? NoContent() : NotFound(result.Error);
    }

    [Authorize(Roles = ApplicationRoles.Admin)]
    [HttpPost("upload-image")]
    public async Task<IActionResult> UploadImage(IFormFile file, CancellationToken cancellationToken = default)
    {
        if (file is null || file.Length == 0)
        {
            return BadRequest(new { Error = "No file provided." });
        }

        if (file.Length > MaxImageBytes)
        {
            return BadRequest(new { Error = "Image must be smaller than 10MB." });
        }

        if (!AllowedImageContentTypes.Contains(file.ContentType))
        {
            return BadRequest(new { Error = "Image must be jpeg, jpg, png or webp." });
        }

        await using var stream = file.OpenReadStream();
        var result = await _storageService.UploadImageAsync(
            stream,
            file.FileName,
            file.ContentType,
            cancellationToken);

        var imageUrl = await _storageService.GetImageUrlAsync(result.StoredValue, cancellationToken);

        return Ok(new { ImageUrl = imageUrl, StoredValue = result.StoredValue });
    }
}

public sealed record CreateAdminNoteRequest(string Title, string Text, string ImageUrl);
