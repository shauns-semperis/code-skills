#:package Microsoft.CodeAnalysis.CSharp@4.*

// Finds real code references to an identifier across a directory of decompiled
// .cs files, using Roslyn's syntax tree instead of text search. Comments and
// XML doc (<see cref="...">) are trivia, not identifier tokens, so they're
// excluded automatically -- no filtering logic needed, just walking real
// tokens instead of grepping raw text.

using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;

if (args.Length < 2)
{
    Console.Error.WriteLine("Usage: refs.cs <decompiled-dir> <identifier-name>");
    return 1;
}

var dir = args[0];
var name = args[1];
var found = 0;

foreach (var path in Directory.EnumerateFiles(dir, "*.cs", SearchOption.AllDirectories))
{
    string text;
    try { text = File.ReadAllText(path); }
    catch { continue; }

    var tree = CSharpSyntaxTree.ParseText(text);
    var lines = text.Split('\n');

    foreach (var token in tree.GetRoot().DescendantTokens())
    {
        if (!token.IsKind(SyntaxKind.IdentifierToken) || token.Text != name) continue;

        var lineNum = token.GetLocation().GetLineSpan().StartLinePosition.Line;
        var lineText = lineNum < lines.Length ? lines[lineNum].Trim() : "";
        Console.WriteLine($"{path}:{lineNum + 1}: {lineText}");
        found++;
    }
}

if (found == 0)
{
    Console.Error.WriteLine($"# No code references to '{name}' found (comments/doc-only mentions are intentionally excluded).");
    return 1;
}

return 0;
