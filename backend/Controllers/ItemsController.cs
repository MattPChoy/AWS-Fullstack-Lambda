using Amazon.DynamoDBv2.DataModel;
using Microsoft.AspNetCore.Mvc;
using VueCSharpApi.Models;
using System.Collections.Generic;

namespace VueCSharpApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ItemsController : ControllerBase
{
    private readonly IDynamoDBContext _dynamoDbContext;
    private readonly ILogger<ItemsController> _logger;

    public ItemsController(IDynamoDBContext dynamoDbContext, ILogger<ItemsController> logger)
    {
        _dynamoDbContext = dynamoDbContext;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Item>>> GetItems()
    {
        try
        {
            var items = await _dynamoDbContext.ScanAsync<Item>(new List<ScanCondition>()).GetRemainingAsync();
            return Ok(items);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving items from DynamoDB");
            return StatusCode(500, "Error retrieving items");
        }
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Item>> GetItem(string id)
    {
        try
        {
            var item = await _dynamoDbContext.LoadAsync<Item>(id);
            if (item == null)
            {
                return NotFound();
            }
            return Ok(item);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving item {Id} from DynamoDB", id);
            return StatusCode(500, "Error retrieving item");
        }
    }

    [HttpPost]
    public async Task<ActionResult<Item>> CreateItem([FromBody] Item item)
    {
        try
        {
            item.Id = Guid.NewGuid().ToString();
            item.CreatedAt = DateTime.UtcNow;
            await _dynamoDbContext.SaveAsync(item);
            return CreatedAtAction(nameof(GetItem), new { id = item.Id }, item);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating item in DynamoDB");
            return StatusCode(500, "Error creating item");
        }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateItem(string id, [FromBody] Item item)
    {
        try
        {
            var existingItem = await _dynamoDbContext.LoadAsync<Item>(id);
            if (existingItem == null)
            {
                return NotFound();
            }

            item.Id = id;
            item.CreatedAt = existingItem.CreatedAt;
            await _dynamoDbContext.SaveAsync(item);
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating item {Id} in DynamoDB", id);
            return StatusCode(500, "Error updating item");
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteItem(string id)
    {
        try
        {
            var existingItem = await _dynamoDbContext.LoadAsync<Item>(id);
            if (existingItem == null)
            {
                return NotFound();
            }

            await _dynamoDbContext.DeleteAsync<Item>(id);
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting item {Id} from DynamoDB", id);
            return StatusCode(500, "Error deleting item");
        }
    }
}
