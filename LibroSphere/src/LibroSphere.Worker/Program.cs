using LibroSphere.Infrastructure.Configuration;
using LibroSphere.Worker;

DotEnvLoader.LoadFromCurrentDirectory();

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddWorkerServices(builder.Configuration);

var host = builder.Build();
host.Run();
