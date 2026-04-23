# LibroSphere

LibroSphere is a full-stack digital bookstore and reading platform built with Flutter, .NET, Docker, SQL Server, Redis, and RabbitMQ. The project includes:

- a mobile Flutter app for readers
- a Flutter desktop admin panel
- a .NET Web API
- a background worker for asynchronous processing

Project status: `Done`

#Overview

LibroSphere allows users to browse books, purchase them, access their personal library, read purchased titles in an in-app reader, manage a wishlist and cart, leave reviews, and receive notifications.  
The desktop application is intended for administrators and provides catalog management, analytics, reporting, order monitoring, and admin content tools.

## Main Features

### Mobile Application

- User authentication and session management
- Explore/home feed with featured books and recommendations
- Book details with author info, ratings, reviews, and purchase flow
- Shopping cart and order creation
- Wishlist management
- Personal library with access to purchased books
- In-app PDF reader for purchased books
- Review creation and review browsing
- Notifications screen
- Profile management
- Password change
- Order history and refund requests

### Desktop Admin Panel

- Admin login
- Dashboard with analytics and recent activity
- User management
- Book management
- Genre management
- Author management
- Order overview
- PDF report generation
- Admin notes management
- Settings with password change, admin creation, logout, and language switch

### Backend / Infrastructure

- ASP.NET Core Web API
- SQL Server persistence
- Redis integration
- RabbitMQ messaging
- Background worker for async flows
- Swagger documentation
- Seed endpoints for demo catalog data
- JWT authentication
- Stripe configuration for payments
- Cloudflare R2 storage integration for assets

## Technology Stack

- Frontend: Flutter (`mobile` and `desktop`)
- Backend: C# / ASP.NET Core
- Database: Microsoft SQL Server
- Caching: Redis
- Messaging: RabbitMQ / MassTransit
- Payments: Stripe
- File storage: Cloudflare R2
- Deployment / local orchestration: Docker Compose

## Project Structure

```text
LibroSphere/
├── LibroSphere/                    # .NET backend solution
│   ├── src/
│   │   ├── LibroSphere.Domain/
│   │   ├── LibroSphere.Application/
│   │   ├── LibroSphere.Infrastructure/
│   │   ├── LibroSphere.WebApi/
│   │   └── LibroSphere.Worker/
│   └── docker-compose.yml
├── LibroSphere.Frontend/
│   ├── librosphere_mobile/         # Flutter mobile app
│   └── librosphere_desktop/        # Flutter desktop admin app
└── README.md
```

## Demo Accounts

The backend seeds default login accounts from the environment configuration.
###Admin and Desktop accounts and changeable in env file and can be choosen if you want to seed them or not.
### Admin Desktop 


- Email: `admin@librosphere.local`
- Password: `Admin123!`

### Mobile User

- Email: `user@librosphere.local`
- Password: `User123!`

## Running the Project

### 1. Start the backend with Docker

Open a terminal in:

`LibroSphere/`

``

```powershell
docker compose up --build
```

This starts:

- `LibroSphere.Api`
- `LibroSphere.Worker`
- SQL Server
- Redis
- RabbitMQ

### 2. Backend URLs

After startup, the main local endpoints are:
But you can change in Env file port of Api!

- API: [http://localhost:8080](http://localhost:8080)
- Swagger: [http://localhost:8080/swagger](http://localhost:8080/swagger)
- RabbitMQ Management: [http://localhost:15672](http://localhost:15672)

Default RabbitMQ credentials:

- Username: `guest`
- Password: `guest`

### 3. Seed catalog data

Default admin and user accounts are created automatically, but catalog/demo content is exposed through seed endpoints.

After the API is running, sign in through Swagger with the admin account and call:

- `POST /api/Seed/genres`
- `POST /api/Seed/catalog`

You can also trigger these endpoints manually once the admin account is available.

## Running the Mobile App

Open a terminal in:

`LibroSphere.Frontend/librosphere_mobile`

Install dependencies:

```powershell
flutter pub get
```

Run on Android emulator:

```powershell
flutter run -d android
```

By default, the mobile app uses:

- `http://10.0.2.2:8080` on Android emulator
- `http://localhost:8080` on desktop/web targets

If you want to override the API URL manually:

```powershell
flutter run -d android --dart-define=LIBROSPHERE_API_URL=http://10.0.2.2:8080
or just run emulator and type flutter run
```

## Running the Desktop Admin App

Open a terminal in:

`LibroSphere.Frontend/librosphere_desktop`

Install dependencies:

```powershell
flutter pub get
```

Run the Windows desktop app:

```powershell
flutter run -d windows
```

The desktop app uses `http://localhost:8080` by default.

If needed, you can override it explicitly:

```powershell
flutter run -d windows --dart-define=LIBROSPHERE_API_URL=http://localhost:8080
```

## Notes

- Start Docker services before running either Flutter app.
- The desktop app is intended for admin use only.
- The mobile app requires the seeded mobile user account or a newly registered user.
- Purchased books become available inside the mobile library and can be opened in the in-app reader.
- Some asynchronous features depend on the worker and RabbitMQ being active.

## Repository Summary

LibroSphere was built as a complete cross-platform reading ecosystem with:

- a customer-facing mobile reading experience
- a dedicated desktop administration panel
- a modular .NET backend
- Docker-based local setup
- async background processing for system events

It is designed as a practical, production-style university / portfolio project that demonstrates full-stack development across mobile, desktop, backend, infrastructure, and integration services.
