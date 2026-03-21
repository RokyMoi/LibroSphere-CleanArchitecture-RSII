using LibroSphere.Api.Extensions;
using LibroSphere.Services;
using LIbroSphere.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
//Services from Our Layers
builder.Services.AddApplication();
builder.Services.AddInfrastructureServices(builder.Configuration);
///
var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.ApplyMigrations();  
}

app.UseHttpsRedirection();

//app.UseAuthorization();

app.MapControllers();

app.Run();
