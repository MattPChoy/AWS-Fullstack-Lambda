# Vue + C# + DynamoDB Full Stack Application

A full-stack application using Vue 3 with TypeScript, ASP.NET Core Web API, and AWS DynamoDB, orchestrated with .NET Aspire for local development.

## Architecture

- **Frontend**: Vue 3 + TypeScript + Vite + PrimeVue + Axios
- **Backend**: ASP.NET Core Web API + C#
- **Database**: AWS DynamoDB (Local for development)
- **Orchestration**: .NET Aspire

## Project Structure

```
.
├── frontend/                 # Vue 3 + TypeScript application
│   ├── src/
│   │   ├── components/      # Vue components
│   │   ├── services/        # API service layer (Axios)
│   │   └── main.ts          # App entry point
│   └── package.json
├── backend/                  # ASP.NET Core Web API
│   ├── Controllers/         # API controllers
│   ├── Models/              # Data models
│   └── Program.cs           # API configuration
├── VueCSharpApp.AppHost/    # Aspire orchestration
├── VueCSharpApp.ServiceDefaults/  # Aspire service defaults
└── README.md
```

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download)
- [Node.js 18+](https://nodejs.org/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (for DynamoDB Local)
- [AWS CLI](https://aws.amazon.com/cli/) (optional, for AWS deployment)

## Getting Started

.NET Aspire automatically starts all services including DynamoDB Local in Docker containers - this requires having Docker or Podman installed.

**Start the Aspire AppHost** - this should open the aspire dashboard in your browser from which you'll find the link to the front-end (on an ephemeral port) 
   ```bash
   cd VueCSharpApp.AppHost
   dotnet run
   ```
## Configuration

### Backend Configuration

AWS settings are configured in `backend/appsettings.json`:

```json
{
  "AWS": {
    "Region": "ap-southeast-2",
    "Profile": "default"
  }
}
```

For local development with DynamoDB Local, the Aspire AppHost automatically configures the connection.

### Frontend Configuration

API URL is configured via environment variables:
- **Production**: `frontend/.env.production`
  ```
  VITE_API_URL=https://your-api-url.com
  ```
## Deployment
- Requires setting up the [AWS CDK](https://docs.aws.amazon.com/cdk/v2/guide/getting-started.html#getting-started-install)
- Run the `deploy.ps1` script 

## Technology Stack

### Frontend
- **Vue 3**: Progressive JavaScript framework
- **TypeScript**: Type-safe JavaScript
- **Vite**: Fast build tool
- **PrimeVue**: UI component library
- **Axios**: HTTP client

### Backend
- **ASP.NET Core 8**: Web API framework
- **AWS SDK for .NET**: DynamoDB integration
- **.NET Aspire**: Cloud-native orchestration

### Database
- **Amazon DynamoDB**: NoSQL database
- **DynamoDB Local**: Local development database (runs in Docker)

### Port Conflicts

If ports are already in use:
- Backend API: Default is 5000, can be changed in `launchSettings.json`
- Frontend: Default is 5173, Vite will auto-increment if busy
- Aspire Dashboard: Default is 15000
