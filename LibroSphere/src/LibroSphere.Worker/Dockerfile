FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["src/LibroSphere.Worker/LibroSphere.Worker.csproj", "src/LibroSphere.Worker/"]
COPY ["src/LibroSphere.Infrastructure/LibroSphere.Infrastructure.csproj", "src/LibroSphere.Infrastructure/"]
COPY ["src/LibroSphere.Application/LibroSphere.Application.csproj", "src/LibroSphere.Application/"]
COPY ["src/LibroSphere.Domain/LibroSphere.Domain.csproj", "src/LibroSphere.Domain/"]
RUN dotnet restore "src/LibroSphere.Worker/LibroSphere.Worker.csproj"
COPY . .
WORKDIR "/src/src/LibroSphere.Worker"
RUN dotnet build "LibroSphere.Worker.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "LibroSphere.Worker.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "LibroSphere.Worker.dll"]
