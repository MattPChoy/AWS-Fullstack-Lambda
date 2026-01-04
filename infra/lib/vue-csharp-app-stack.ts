import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as path from 'path';

export class VueCSharpAppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // DynamoDB Table
    const itemsTable = new dynamodb.Table(this, 'ItemsTable', {
      tableName: 'Items',
      partitionKey: {
        name: 'Id',
        type: dynamodb.AttributeType.STRING,
      },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // Change to RETAIN for production
      pointInTimeRecovery: true,
    });

    // Lambda function for Backend API (using .NET 8 managed runtime)
    const backendFunction = new lambda.Function(this, 'BackendFunction', {
      runtime: lambda.Runtime.DOTNET_8,
      handler: 'VueCSharpApi',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend'), {
        bundling: {
          image: lambda.Runtime.DOTNET_8.bundlingImage,
          command: [
            '/bin/sh',
            '-c',
            'dotnet publish -c Release -o /asset-output',
          ],
        },
      }),
      memorySize: 1024,
      timeout: cdk.Duration.seconds(30),
      environment: {
        AWS__Region: this.region,
        ASPNETCORE_ENVIRONMENT: 'Production',
      },
    });

    // Grant DynamoDB permissions to Lambda
    itemsTable.grantReadWriteData(backendFunction);

    // API Gateway REST API
    const api = new apigateway.RestApi(this, 'BackendApi', {
      restApiName: 'VueCSharpApi',
      description: 'Vue C# App Backend API',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: [
          'Content-Type',
          'X-Amz-Date',
          'Authorization',
          'X-Api-Key',
          'X-Amz-Security-Token',
        ],
      },
      deployOptions: {
        stageName: 'prod',
        throttlingRateLimit: 100,
        throttlingBurstLimit: 200,
      },
    });

    // Add Lambda integration
    const lambdaIntegration = new apigateway.LambdaIntegration(backendFunction, {
      proxy: true,
    });

    // Add proxy resource to handle all paths
    api.root.addProxy({
      defaultIntegration: lambdaIntegration,
      anyMethod: true,
    });

    // S3 Bucket for Frontend
    const frontendBucket = new s3.Bucket(this, 'FrontendBucket', {
      bucketName: `vue-csharp-frontend-${this.account}`,
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // Origin Access Identity for CloudFront
    const originAccessIdentity = new cloudfront.OriginAccessIdentity(this, 'OAI', {
      comment: 'OAI for Vue frontend',
    });

    // Grant CloudFront OAI read access to S3 bucket
    frontendBucket.grantRead(originAccessIdentity);

    // CloudFront Distribution
    const distribution = new cloudfront.Distribution(this, 'FrontendDistribution', {
      defaultBehavior: {
        origin: new origins.S3Origin(frontendBucket, {
          originAccessIdentity,
        }),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        compress: true,
      },
      additionalBehaviors: {
        'api/*': {
          origin: new origins.RestApiOrigin(api),
          viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.HTTPS_ONLY,
          cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
          allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
          compress: true,
        },
      },
      defaultRootObject: 'index.html',
    });

    // Note: Frontend deployment is handled by the PowerShell script
    // after building with the correct API URL

    // Outputs
    new cdk.CfnOutput(this, 'DynamoDBTableName', {
      value: itemsTable.tableName,
      description: 'DynamoDB Table Name',
      exportName: 'ItemsTableName',
    });

    new cdk.CfnOutput(this, 'BackendApiUrl', {
      value: api.url,
      description: 'Backend API URL',
      exportName: 'BackendApiUrl',
    });

    new cdk.CfnOutput(this, 'FrontendUrl', {
      value: `https://${distribution.distributionDomainName}`,
      description: 'Frontend CloudFront URL',
      exportName: 'FrontendUrl',
    });

    new cdk.CfnOutput(this, 'FrontendBucketName', {
      value: frontendBucket.bucketName,
      description: 'Frontend S3 Bucket Name',
      exportName: 'FrontendBucketName',
    });

    new cdk.CfnOutput(this, 'CloudFrontDistributionId', {
      value: distribution.distributionId,
      description: 'CloudFront Distribution ID',
      exportName: 'CloudFrontDistributionId',
    });
  }
}
