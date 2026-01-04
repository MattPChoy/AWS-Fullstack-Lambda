# Infrastructure

This directory contains the AWS CDK infrastructure code for deploying the Vue + C# application.

## Architecture

- **Frontend**: Vue 3 app deployed to S3 + CloudFront
- **Backend**: ASP.NET Core API running on Lambda + API Gateway
- **Database**: DynamoDB table

## Prerequisites

- [Node.js 18+](https://nodejs.org/)
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- [AWS CDK](https://aws.amazon.com/cdk/) (installed via npm in this project)

## Deployment

### Using the PowerShell Script (Recommended)

From the project root:

```powershell
# Deploy the application
.\deploy.ps1

# Destroy the stack
.\deploy.ps1 -DestroyStack
```

### Manual Deployment

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Bootstrap CDK** (first time only):
   ```bash
   npx cdk bootstrap
   ```

3. **Deploy the stack**:
   ```bash
   npm run deploy
   ```

4. **Build and deploy frontend**:
   ```bash
   cd ../frontend

   # Set the API URL from CDK outputs
   echo "VITE_API_URL=<YOUR_API_URL>" > .env.production

   # Build
   npm run build

   # Upload to S3
   aws s3 sync dist/ s3://<YOUR_BUCKET_NAME>/ --delete

   # Invalidate CloudFront
   aws cloudfront create-invalidation --distribution-id <YOUR_DIST_ID> --paths "/*"
   ```

## CDK Commands

- `npm run build` - Compile TypeScript to JavaScript
- `npm run watch` - Watch for changes and compile
- `npm run cdk synth` - Synthesize CloudFormation template
- `npm run cdk diff` - Compare deployed stack with current state
- `npm run deploy` - Deploy the stack
- `npm run destroy` - Destroy the stack

## Stack Outputs

After deployment, the stack provides these outputs:

- `BackendApiUrl` - API Gateway URL for the backend
- `FrontendUrl` - CloudFront URL for the frontend
- `FrontendBucketName` - S3 bucket name
- `CloudFrontDistributionId` - CloudFront distribution ID
- `DynamoDBTableName` - DynamoDB table name

## Configuration

The infrastructure uses these default settings:

- **Region**: `ap-southeast-2` (can be changed in `bin/app.ts`)
- **Lambda Memory**: 1024 MB
- **Lambda Timeout**: 30 seconds
- **DynamoDB**: Pay-per-request billing
- **API Gateway**: Throttling at 100 req/s (burst: 200)

## Cost Optimization

- DynamoDB uses on-demand billing (pay only for what you use)
- Lambda only charges for execution time
- S3 and CloudFront have free tier coverage for low traffic
- Consider using AWS Cost Explorer to monitor costs

## Cleanup

To remove all resources:

```powershell
.\deploy.ps1 -DestroyStack
```

Or manually:

```bash
cd infra
npm run destroy
```
