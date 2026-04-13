using LibroSphere.Api.Extensions;
using LibroSphere.Infrastructure;
using LibroSphere.Services;

var builder = WebApplication.CreateBuilder(args);


builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


builder.Services.AddApplication();
builder.Services.AddInfrastructureServices(builder.Configuration);

var app = builder.Build();


if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.ApplyMigrations();
}

await app.SeedIdentityAsync();

app.UseHttpsRedirection();
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/api/payment/webhook"))
        context.Request.EnableBuffering();
    await next();
});


app.UseAuthentication();
app.UseAuthorization();



app.UseCustomMiddleWare(); 

app.MapControllers();

app.Run();
