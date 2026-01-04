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

- [.NET 9 SDK](https://dotnet.microsoft.com/download)
- [Node.js 18+](https://nodejs.org/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (for DynamoDB Local)
- [AWS CLI](https://aws.amazon.com/cli/) (optional, for AWS deployment)

## Getting Started

### Option 1: Run with .NET Aspire (Recommended for Development)

.NET Aspire automatically starts all services including DynamoDB Local in Docker containers.

1. **Start the Aspire AppHost**:
   ```bash
   cd VueCSharpApp.AppHost
   dotnet run
   ```

2. **Access the Aspire Dashboard**:
   - Open your browser to the URL shown in the console (typically `http://localhost:15000`)
   - The dashboard shows all running services and their health status

3. **Start the Vue frontend**:
   ```bash
   cd frontend
   npm run dev
   ```

4. **Access the application**:
   - Frontend: http://localhost:5173
   - Backend API: Check the Aspire dashboard for the API endpoint
   - Aspire Dashboard: http://localhost:15000

### Option 2: Run Services Manually

If you prefer to run services individually without Aspire:

1. **Start DynamoDB Local**:
   ```bash
   docker run -p 8000:8000 amazon/dynamodb-local
   ```

2. **Create the DynamoDB table**:
   ```bash
   aws dynamodb create-table \
     --table-name Items \
     --attribute-definitions AttributeName=Id,AttributeType=S \
     --key-schema AttributeName=Id,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --endpoint-url http://localhost:8000 \
     --region ap-southeast-2
   ```

3. **Run the backend API**:
   ```bash
   cd backend
   dotnet run
   ```

4. **Run the frontend**:
   ```bash
   cd frontend
   npm run dev
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

- **Development**: `frontend/.env.development`
  ```
  VITE_API_URL=http://localhost:5000
  ```

- **Production**: `frontend/.env.production`
  ```
  VITE_API_URL=https://your-api-url.com
  ```

## Development in Visual Studio or Rider

1. **Open the solution**:
   - Open `VueCSharpApp.AppHost.csproj` in Visual Studio or Rider
   - Or create a solution file containing all projects

2. **Set the AppHost as the startup project**

3. **Press F5 to debug**:
   - Aspire will start all services
   - You can set breakpoints in the backend API
   - View service logs in the Aspire dashboard

4. **Run the Vue frontend separately**:
   ```bash
   cd frontend
   npm run dev
   ```

## API Endpoints

### Items Controller

- `GET /api/items` - Get all items
- `GET /api/items/{id}` - Get item by ID
- `POST /api/items` - Create new item
- `PUT /api/items/{id}` - Update item
- `DELETE /api/items/{id}` - Delete item

### Example Request

```bash
# Create an item
curl -X POST http://localhost:5000/api/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sample Item",
    "description": "This is a sample item"
  }'
```

## Deployment

### Backend Deployment to AWS

The backend API can be deployed to:
- AWS Elastic Beanstalk
- AWS App Runner
- Amazon ECS/EKS
- AWS Lambda (with minimal modifications)

Configure the production DynamoDB table name and AWS region in production appsettings.

### Frontend Deployment

The Vue frontend can be deployed to:
- AWS S3 + CloudFront
- AWS Amplify
- Vercel
- Netlify

Build the frontend:
```bash
cd frontend
npm run build
```

The production build will be in `frontend/dist/`.

## Technology Stack

### Frontend
- **Vue 3**: Progressive JavaScript framework
- **TypeScript**: Type-safe JavaScript
- **Vite**: Fast build tool
- **PrimeVue**: UI component library
- **Axios**: HTTP client

### Backend
- **ASP.NET Core 9**: Web API framework
- **AWS SDK for .NET**: DynamoDB integration
- **.NET Aspire**: Cloud-native orchestration

### Database
- **Amazon DynamoDB**: NoSQL database
- **DynamoDB Local**: Local development database (Docker)

## Troubleshooting

### DynamoDB Connection Issues

If the API can't connect to DynamoDB Local:
1. Ensure Docker is running
2. Check that DynamoDB Local is running on port 8000
3. Verify the table exists using AWS CLI:
   ```bash
   aws dynamodb list-tables --endpoint-url http://localhost:8000 --region ap-southeast-2
   ```

### CORS Issues

If the frontend can't connect to the API:
1. Check that the API URL in `.env.development` matches the running API
2. Verify CORS settings in `backend/Program.cs`
3. Ensure the frontend origin is allowed in the CORS policy

### Port Conflicts

If ports are already in use:
- Backend API: Default is 5000, can be changed in `launchSettings.json`
- Frontend: Default is 5173, Vite will auto-increment if busy
- Aspire Dashboard: Default is 15000

## License

MIT
