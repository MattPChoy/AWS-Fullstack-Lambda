var builder = DistributedApplication.CreateBuilder(args);

// Add DynamoDB Local
var dynamodb = builder.AddAWSDynamoDBLocal("dynamodb");

// Add the backend API
var api = builder.AddProject<Projects.VueCSharpApi>("api")
    .WithReference(dynamodb)
    .WithExternalHttpEndpoints();

// Add the Vue frontend with proxy to backend
var frontend = builder.AddNpmApp("frontend", "../frontend", "dev")
    .WithReference(api)
    .WithHttpEndpoint(env: "PORT")
    .WithExternalHttpEndpoints();

builder.Build().Run();
