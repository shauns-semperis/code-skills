# Scenario 5: Test Names Include Fixture/Context Noise

## RED Baseline (without skill)

This is a test written without guidance. Note the test name problem:

```csharp
[Theory]
[InlineData("{\"name\":\"Alice\"}")]
[InlineData("{\"name\":\"Bob\"}")]
public void Parse_JsonData_ReturnsUser(string json, string expectedName)
{
    var result = _parser.Parse(json);
    Assert.Equal(expectedName, result.Name);
}
```

## The Problem

The test name includes fixture/context noise:
- `JsonData` is test data (the specific format being parsed)
- The name makes it sound like "parsing JSON specifically" is what's being tested
- But actually: **We're testing that deserialization works correctly**

The test would work identically with CSV data, XML data, or any other format. The format is just a mechanism to trigger the parsing behavior - it's not what we're testing.

## Expected Behavior (with skill)

Agents should strip away fixture context and name tests for the **actual behavior being verified**:

```csharp
// ✅ Better: Describes what's actually being tested
[Theory]
[InlineData("{\"name\":\"Alice\"}")]
[InlineData("{\"name\":\"Bob\"}")]
public void Parse_ValidInput_ReturnsDeserializedObject(string json, string expectedName)
{
    var result = _parser.Parse(json);
    Assert.Equal(expectedName, result.Name);
}
```

The name now clearly indicates: "We're parsing/deserializing and verifying the result is correct" - not "we're parsing JSON specifically."
