var builder = DistributedApplication.CreateBuilder(args);

// Add DynamoDB Local
var dynamodb = builder.AddAWSDynamoDBLocal("dynamodb");

// Add the backend API with a fixed port
var api = builder.AddProject<Projects.VueCSharpApi>("api")
    .WithReference(dynamodb)
    .WithHttpEndpoint(port: 5063, name: "api-http");

builder.Build().Run();
