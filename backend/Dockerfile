FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY backend ./backend
RUN echo "Backend scaffold only - add .csproj files to enable build."

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
EXPOSE 8080
CMD ["/bin/sh", "-c", "echo 'Backend scaffold is ready'; sleep infinity"]
