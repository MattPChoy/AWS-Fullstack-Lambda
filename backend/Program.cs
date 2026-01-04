using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using VueCSharpApi.Services;

var builder = WebApplication.CreateBuilder(args);

// Add Aspire service defaults for local development
#if DEBUG
if (!builder.Environment.IsProduction())
{
    builder.AddServiceDefaults();
}
#endif

// Add AWS Lambda support
builder.Services.AddAWSLambdaHosting(LambdaEventSource.RestApi);

// Add services to the container
builder.Services.AddControllers();

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Configure DynamoDB
var awsOptions = builder.Configuration.GetAWSOptions();
builder.Services.AddDefaultAWSOptions(awsOptions);
builder.Services.AddAWSService<IAmazonDynamoDB>();
builder.Services.AddScoped<IDynamoDBContext, DynamoDBContext>();
builder.Services.AddSingleton<DynamoDbInitializer>();

var app = builder.Build();

// Initialize DynamoDB tables
using (var scope = app.Services.CreateScope())
{
    var initializer = scope.ServiceProvider.GetRequiredService<DynamoDbInitializer>();
    await initializer.InitializeAsync();
}

app.UseCors("AllowAll");
app.MapControllers();

app.Run();
