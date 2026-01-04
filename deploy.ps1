#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploys the Vue + C# + DynamoDB application to AWS using CDK

.DESCRIPTION
    This script deploys the full-stack application to AWS:
    - Backend: ASP.NET Core API on Lambda + API Gateway
    - Frontend: Vue 3 app on S3 + CloudFront
    - Database: DynamoDB table

.PARAMETER SkipBuild
    Skip building the frontend (uses existing dist folder)

.PARAMETER DestroyStack
    Destroy the CloudFormation stack instead of deploying

.EXAMPLE
    .\deploy.ps1
    Deploys the application to AWS

.EXAMPLE
    .\deploy.ps1 -DestroyStack
    Destroys the deployed stack
#>

param(
    [switch]$SkipBuild,
    [switch]$DestroyStack
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-ErrorMsg { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Step { param($msg) Write-Host "`n>>> $msg" -ForegroundColor Yellow }

# Get script directory
$scriptDir = $PSScriptRoot
$infraDir = Join-Path $scriptDir "infra"
$frontendDir = Join-Path $scriptDir "frontend"
$backendDir = Join-Path $scriptDir "backend"

# Validate prerequisites
Write-Step "Validating prerequisites..."

# Check AWS CLI
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "AWS CLI is not installed. Please install it first."
    exit 1
}

# Check Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "Node.js is not installed. Please install it first."
    exit 1
}

# Check npm
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "npm is not installed. Please install it first."
    exit 1
}

# Check .NET
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg ".NET SDK is not installed. Please install it first."
    exit 1
}

# Check AWS credentials
try {
    $awsAccount = aws sts get-caller-identity --query Account --output text
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get AWS account"
    }
    Write-Success "AWS credentials configured (Account: $awsAccount)"
} catch {
    Write-ErrorMsg "AWS credentials not configured. Please run 'aws configure'"
    exit 1
}

# Handle destroy
if ($DestroyStack) {
    Write-Step "Destroying CloudFormation stack..."

    Push-Location $infraDir
    try {
        npm run destroy
        if ($LASTEXITCODE -ne 0) {
            throw "CDK destroy failed"
        }
        Write-Success "Stack destroyed successfully"
    } finally {
        Pop-Location
    }

    exit 0
}

# Install CDK dependencies
Write-Step "Installing CDK dependencies..."
Push-Location $infraDir
try {
    if (-not (Test-Path "node_modules")) {
        Write-Info "Running npm install in infra directory..."
        npm install
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed in infra directory"
        }
    }
    Write-Success "CDK dependencies ready"
} finally {
    Pop-Location
}

# Bootstrap CDK (if needed)
Write-Step "Checking CDK bootstrap status..."
Push-Location $infraDir
try {
    $region = aws configure get region
    if (-not $region) {
        $region = "ap-southeast-2"
        Write-Info "No default region set, using $region"
    }

    Write-Info "Bootstrapping CDK in region $region..."
    npx cdk bootstrap aws://$awsAccount/$region
    if ($LASTEXITCODE -ne 0) {
        throw "CDK bootstrap failed"
    }
    Write-Success "CDK bootstrapped"
} finally {
    Pop-Location
}

# Deploy CDK stack (without frontend)
Write-Step "Deploying CDK stack..."
Push-Location $infraDir
try {
    Write-Info "Running CDK deploy..."
    npm run deploy
    if ($LASTEXITCODE -ne 0) {
        throw "CDK deploy failed"
    }
    Write-Success "CDK stack deployed"
} finally {
    Pop-Location
}

# Get stack outputs
Write-Step "Retrieving stack outputs..."
$apiUrl = aws cloudformation describe-stacks `
    --stack-name VueCSharpAppStack `
    --query "Stacks[0].Outputs[?OutputKey=='BackendApiUrl'].OutputValue" `
    --output text

$bucketName = aws cloudformation describe-stacks `
    --stack-name VueCSharpAppStack `
    --query "Stacks[0].Outputs[?OutputKey=='FrontendBucketName'].OutputValue" `
    --output text

$distributionId = aws cloudformation describe-stacks `
    --stack-name VueCSharpAppStack `
    --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue" `
    --output text

$frontendUrl = aws cloudformation describe-stacks `
    --stack-name VueCSharpAppStack `
    --query "Stacks[0].Outputs[?OutputKey=='FrontendUrl'].OutputValue" `
    --output text

if (-not $apiUrl -or -not $bucketName -or -not $distributionId) {
    Write-ErrorMsg "Failed to retrieve stack outputs"
    exit 1
}

Write-Success "API URL: $apiUrl"
Write-Success "Frontend Bucket: $bucketName"
Write-Success "CloudFront Distribution: $distributionId"

# Build frontend with production API URL
if (-not $SkipBuild) {
    Write-Step "Building frontend..."
    Push-Location $frontendDir
    try {
        # Install dependencies if needed
        if (-not (Test-Path "node_modules")) {
            Write-Info "Running npm install in frontend directory..."
            npm install
            if ($LASTEXITCODE -ne 0) {
                throw "npm install failed in frontend directory"
            }
        }

        # Create production env file
        Write-Info "Creating .env.production with API URL..."
        "VITE_API_URL=$apiUrl" | Out-File -FilePath ".env.production" -Encoding utf8

        # Build frontend
        Write-Info "Building frontend for production..."
        npm run build
        if ($LASTEXITCODE -ne 0) {
            throw "Frontend build failed"
        }
        Write-Success "Frontend built successfully"
    } finally {
        Pop-Location
    }
}

# Deploy frontend to S3
Write-Step "Deploying frontend to S3..."
$distDir = Join-Path $frontendDir "dist"
if (-not (Test-Path $distDir)) {
    Write-ErrorMsg "Frontend dist folder not found. Please build the frontend first."
    exit 1
}

Write-Info "Uploading files to S3..."
aws s3 sync $distDir "s3://$bucketName" --delete --cache-control "public, max-age=31536000"
if ($LASTEXITCODE -ne 0) {
    Write-ErrorMsg "Failed to upload frontend to S3"
    exit 1
}

# Update cache-control for index.html
Write-Info "Setting cache-control for index.html..."
aws s3 cp "s3://$bucketName/index.html" "s3://$bucketName/index.html" `
    --metadata-directive REPLACE `
    --cache-control "public, max-age=0, must-revalidate" `
    --content-type "text/html"

Write-Success "Frontend deployed to S3"

# Invalidate CloudFront cache
Write-Step "Invalidating CloudFront cache..."
$invalidationId = aws cloudfront create-invalidation `
    --distribution-id $distributionId `
    --paths "/*" `
    --query "Invalidation.Id" `
    --output text

if ($LASTEXITCODE -ne 0) {
    Write-ErrorMsg "Failed to create CloudFront invalidation"
    exit 1
}

Write-Success "CloudFront invalidation created: $invalidationId"

# Summary
Write-Step "Deployment Complete!"
Write-Host ""
Write-Host "===================================================" -ForegroundColor Magenta
Write-Host "  Application URLs:" -ForegroundColor Magenta
Write-Host "===================================================" -ForegroundColor Magenta
Write-Host "  Frontend: " -NoNewline
Write-Host $frontendUrl -ForegroundColor Green
Write-Host "  Backend API: " -NoNewline
Write-Host $apiUrl -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Magenta
Write-Host ""
Write-Info "CloudFront invalidation in progress. Changes may take a few minutes to propagate."
Write-Host ""
