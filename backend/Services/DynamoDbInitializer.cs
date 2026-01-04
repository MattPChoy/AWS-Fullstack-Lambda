using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;

namespace VueCSharpApi.Services;

public class DynamoDbInitializer
{
    private readonly IAmazonDynamoDB _dynamoDbClient;
    private readonly ILogger<DynamoDbInitializer> _logger;

    public DynamoDbInitializer(IAmazonDynamoDB dynamoDbClient, ILogger<DynamoDbInitializer> logger)
    {
        _dynamoDbClient = dynamoDbClient;
        _logger = logger;
    }

    public async Task InitializeAsync()
    {
        var tableName = "Items";

        try
        {
            // Check if table exists
            var existingTables = await _dynamoDbClient.ListTablesAsync();
            if (existingTables.TableNames.Contains(tableName))
            {
                _logger.LogInformation("DynamoDB table '{TableName}' already exists", tableName);
                return;
            }

            // Create table
            _logger.LogInformation("Creating DynamoDB table '{TableName}'...", tableName);

            var request = new CreateTableRequest
            {
                TableName = tableName,
                AttributeDefinitions = new List<AttributeDefinition>
                {
                    new AttributeDefinition
                    {
                        AttributeName = "Id",
                        AttributeType = ScalarAttributeType.S
                    }
                },
                KeySchema = new List<KeySchemaElement>
                {
                    new KeySchemaElement
                    {
                        AttributeName = "Id",
                        KeyType = KeyType.HASH
                    }
                },
                BillingMode = BillingMode.PAY_PER_REQUEST
            };

            await _dynamoDbClient.CreateTableAsync(request);

            // Wait for table to be active
            var tableDescription = await WaitForTableToBeActive(tableName);
            _logger.LogInformation("DynamoDB table '{TableName}' created successfully", tableName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error initializing DynamoDB table '{TableName}'", tableName);
            throw;
        }
    }

    private async Task<TableDescription> WaitForTableToBeActive(string tableName)
    {
        var maxAttempts = 10;
        var attempt = 0;

        while (attempt < maxAttempts)
        {
            try
            {
                var response = await _dynamoDbClient.DescribeTableAsync(tableName);
                if (response.Table.TableStatus == TableStatus.ACTIVE)
                {
                    return response.Table;
                }

                _logger.LogInformation("Waiting for table '{TableName}' to become active... (Status: {Status})",
                    tableName, response.Table.TableStatus);

                await Task.Delay(1000);
                attempt++;
            }
            catch (ResourceNotFoundException)
            {
                _logger.LogWarning("Table '{TableName}' not found yet, waiting...", tableName);
                await Task.Delay(1000);
                attempt++;
            }
        }

        throw new Exception($"Table '{tableName}' did not become active within the expected time");
    }
}
