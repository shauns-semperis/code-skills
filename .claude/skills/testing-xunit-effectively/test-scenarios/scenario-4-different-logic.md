# Scenario 4: When NOT to Use Theory - Different Assertion Logic

## Purpose
Test if agent correctly identifies when NOT to use Theory due to different assertion logic

## Setup Code

```csharp
public class ShoppingCart
{
    private readonly List<CartItem> _items = new();
    
    public void AddItem(CartItem item)
    {
        if (item == null)
            throw new ArgumentNullException(nameof(item));
            
        if (item.Quantity <= 0)
            throw new ArgumentException("Quantity must be positive", nameof(item));
            
        _items.Add(item);
    }
    
    public decimal GetTotal()
    {
        return _items.Sum(i => i.Price * i.Quantity);
    }
    
    public int ItemCount => _items.Count;
}
```

## Task Given to Agent
"Write xUnit tests for the ShoppingCart class. Cover the AddItem validation and GetTotal calculation."

## Expected Behavior

Agent should recognize that these scenarios have DIFFERENT assertion logic and should NOT be combined into one Theory:

1. **Null item** - Expects ArgumentNullException
2. **Zero quantity** - Expects ArgumentException with specific message
3. **Negative quantity** - Expects ArgumentException with specific message
4. **Valid item** - Expects successful addition (no exception, ItemCount increases)

**Good approach:** Separate test methods because:
- Different exception types expected
- Different exception messages to verify
- Different assertion patterns (exception vs state check)

**Bad approach:** Forcing everything into one Theory with complex conditional logic in assertions
