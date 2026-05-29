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
    private static readonly byte[] JpegMagicBytes = { 0xFF, 0xD8, 0xFF };
    private static readonly byte[] PngMagicBytes = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };
    private static readonly byte[] WebpRiffMagicBytes = { 0x52, 0x49, 0x46, 0x46 };
    private static readonly byte[] WebpWebpMagicBytes = { 0x57, 0x45, 0x42, 0x50 };

    public AdminNotesController(ISender sender, IBookAssetStorageService storageService)
    {
        _sender = sender;
        _storageService = storageService;
    }

    [Authorize(Roles = ApplicationRoles.Admin)]
    [HttpGet]
    public async Task<IActionResult> GetLatest(
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        take = Math.Clamp(take, 1, 100);
        var result = await _sender.Send(new GetLatestAdminNotesQuery(take), cancellationToken);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    [Authorize(Roles = ApplicationRoles.Admin)]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateAdminNoteRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Title) || request.Title.Length > 200)
            return BadRequest(new { Error = "Title is required and must be 200 characters or fewer." });

        if (string.IsNullOrWhiteSpace(request.Text) || request.Text.Length > 5000)
            return BadRequest(new { Error = "Text is required and must be 5000 characters or fewer." });

        if (!string.IsNullOrEmpty(request.ImageUrl) &&
            (!Uri.TryCreate(request.ImageUrl, UriKind.Absolute, out var uri) ||
             (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp)))
            return BadRequest(new { Error = "ImageUrl must be a valid absolute HTTP/HTTPS URL." });

        var result = await _sender.Send(
            new CreateAdminNoteCommand(request.Title, request.Text, request.ImageUrl),
            cancellationToken);

        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    [Authorize(Roles = ApplicationRoles.Admin)]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(id) || id.Length > 100 ||
            !System.Text.RegularExpressions.Regex.IsMatch(id, @"^[a-zA-Z0-9\-_]+$"))
            return BadRequest(new { Error = "Invalid note ID." });

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
        if (!await HasValidImageMagicBytesAsync(stream))
        {
            return BadRequest(new { Error = "File is not a valid JPEG, PNG, or WebP image." });
        }
        stream.Position = 0;

        var result = await _storageService.UploadImageAsync(
            stream,
            file.FileName,
            file.ContentType,
            cancellationToken);

        var imageUrl = await _storageService.GetImageUrlAsync(result.StoredValue, cancellationToken);

        return Ok(new { ImageUrl = imageUrl, StoredValue = result.StoredValue });
    }

    private static async Task<bool> HasValidImageMagicBytesAsync(Stream stream)
    {
        var buffer = new byte[12];
        var bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length);
        if (bytesRead < 4) return false;

        if (bytesRead >= 3 && buffer[0] == JpegMagicBytes[0] && buffer[1] == JpegMagicBytes[1] && buffer[2] == JpegMagicBytes[2])
            return true;

        if (bytesRead >= 8 && buffer.Take(8).SequenceEqual(PngMagicBytes))
            return true;

        if (bytesRead >= 12 && buffer.Take(4).SequenceEqual(WebpRiffMagicBytes) && buffer.Skip(8).Take(4).SequenceEqual(WebpWebpMagicBytes))
            return true;

        return false;
    }
}

public sealed record CreateAdminNoteRequest(string Title, string Text, string ImageUrl);
