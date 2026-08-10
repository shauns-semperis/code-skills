# Wire Format Evolution

For distributed systems, serialized data must work across versions. Require both directions for zero-downtime rolling upgrades:

- **Backward compatibility**: Old writers → New readers (readers must handle old format)
- **Forward compatibility**: New writers → Old readers (writers must avoid new features during rollout)

## Four-Phase Rollout Strategy

**Phase 1: Read-side support** (release v1.1)
Deploy readers that understand BOTH old and new message formats. Old and new writers still produce v1 format.

```csharp
public object Deserialize(byte[] data, string manifest) => manifest switch
{
    "Heartbeat" => DeserializeHeartbeatV1(data),
    "HeartbeatV2" => DeserializeHeartbeatV2(data),  // Can read new, but not yet producing it
    _ => throw new NotSupportedException()
};
```

**Phase 2: Write-side support** (release v1.2, AFTER all readers upgraded)
Only after all nodes read both formats, enable writers to produce new format. Old format still readable.

**Phase 3: Default to new format** (release v2.0, next major)
Make new format the default. Old format still read for backward compatibility.

**Phase 4: Remove old format** (release v3.0, only in next major)
Drop support for old format entirely.

**Key principle**: Always deploy readers before writers. If a new node writes but old nodes haven't upgraded their readers, you've broken production.

## Defensive Serialization

```csharp
public sealed class WidgetDto
{
    [JsonPropertyName("id")]
    public int Id { get; init; }

    [JsonPropertyName("name")]
    public required string Name { get; init; }

    [JsonPropertyName("category")]
    public string? Category { get; init; }  // Null if missing — gracefully handles removal

    [JsonPropertyName("priority")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int Priority { get; init; }  // Don't send default — receivers ignore missing

    // When reading old messages, this new field will be null:
    [JsonPropertyName("sku")]
    public string? Sku { get; init; }
}
```

**Critical patterns:**
1. **Use `[JsonPropertyName]` always** — names your contract separately from code, so renaming code doesn't break wire format
2. **Make new properties nullable** — old messages won't have them
3. **Use `[JsonIgnore(WhenWritingDefault)]`** — don't pollute messages with default values
4. **Test deserialization of old format** — deserialize real v1 messages to confirm new code handles them

**Enum serialization**: Use `[JsonConverter(typeof(JsonStringEnumConverter))]` for string-based enums. Integer-based enums break when members are reordered or a new value is inserted mid-list.

## Choosing a Serialization Format

Schema-based formats hold wire compatibility far better than reflection-based ones:

| Format | Type | Wire Compatibility |
|--------|------|--------------------|
| Protocol Buffers | Schema-based | Excellent — explicit field numbers |
| MessagePack (with contracts) | Schema-based | Good |
| `System.Text.Json` (with source generation) | Schema-based | Good — explicit properties |
| Newtonsoft.Json | Reflection-based | Poor — type names leak into the payload |
| `BinaryFormatter` | Reflection-based | Do not use — deprecated and insecure |

Avoid embedding type names in the payload (e.g. `"$type": "MyApp.Order, MyApp"`) — renaming or moving a class then breaks the wire format. Use an explicit string discriminator (`"type": "order"`) instead.
