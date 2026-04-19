FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["src/LibroSphere.WebApi/LibroSphere.WebApi.csproj", "src/LibroSphere.WebApi/"]
COPY ["src/LibroSphere.Infrastructure/LibroSphere.Infrastructure.csproj", "src/LibroSphere.Infrastructure/"]
COPY ["src/LibroSphere.Application/LibroSphere.Application.csproj", "src/LibroSphere.Application/"]
COPY ["src/LibroSphere.Domain/LibroSphere.Domain.csproj", "src/LibroSphere.Domain/"]
RUN dotnet restore "src/LibroSphere.WebApi/LibroSphere.WebApi.csproj"
COPY . .
WORKDIR "/src/src/LibroSphere.WebApi"
RUN dotnet build "LibroSphere.WebApi.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "LibroSphere.WebApi.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "LibroSphere.WebApi.dll"]
