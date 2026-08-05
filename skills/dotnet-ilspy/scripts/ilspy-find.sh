#!/usr/bin/env bash
# Decompile a narrow slice of an assembly and grep it, instead of dumping a whole
# class or assembly into the conversation. Every full-class decompile costs tens
# of thousands of tokens; this script keeps only the lines that matter in context.
set -euo pipefail

# Hard ceiling on lines printed to stdout, regardless of pattern or context. This
# is what actually protects token usage: a broad search pattern (or a large
# context) can match almost the whole file, silently defeating the point of
# narrowing down before decompiling. The cap can't be worked around by request —
# if you truly need more than this, read the temp file directly and say so.
MAX_OUTPUT_LINES=150

# How long a cached decompile is kept before it's treated as stale and swept.
# Rebuilding the same path invalidates its cache entry immediately (the
# fingerprint below changes), so this is only about not letting /tmp fill up
# with decompiles of DLLs nobody's asked about in a week.
CACHE_MAX_AGE_DAYS=7

usage() {
  cat <<'EOF'
Usage:
  ilspy-find.sh list <assembly.dll> <name-pattern>
      List types whose name matches <name-pattern> (case-insensitive / fuzzy).

  ilspy-find.sh grep <assembly.dll> <type-name> <search-pattern> [context-lines]
      Decompile only <type-name> and print lines matching <search-pattern>,
      with [context-lines] of surrounding context (default 15).
      Output is capped at 150 lines no matter how broad the pattern is —
      a broad pattern (e.g. ".") gets truncated, not a full dump.
      <search-pattern> is a regex — search several things in one call with
      alternation ("Deserialize|GetTypeInfo|ReadFromSpan") instead of one
      grep call per term. Repeat calls against the same type reuse its
      cached decompile, so splitting into several calls anyway is cheap.

  ilspy-find.sh peek <assembly.dll> <type-name> [line-count]
      Print just the first [line-count] lines of <type-name> (default 60).
      Use this — not a raw `dnx ilspycmd -t` dump — when you want to eyeball
      a type's shape (fields, method signatures) rather than search it.

  ilspy-find.sh api <assembly.dll> <type-name>
      Print just the public/protected/internal member declarations of
      <type-name> — signatures only, not implementation bodies. Use this
      to see a type's shape without paying for the full decompile.

  ilspy-find.sh search <assembly.dll> <search-pattern> [context-lines]
      Search across every type in the assembly, not just one — e.g. "find
      every place CashRegister is referenced". Decompiles the whole
      assembly once (one file per type) and caches it by the assembly's
      path/size/mtime, so repeated searches against the same build reuse
      the decompile instead of redoing it. Output is capped like `grep`.
      This is plain text search — matches inside comments and XML doc
      (<see cref="...">) count too, which is often ~1/3 of the hits.

  ilspy-find.sh refs <assembly.dll> <identifier-name>
      Like `search`, but only real code references — not comments, not
      XML doc mentions. Uses Roslyn to parse the decompiled source and
      walk actual identifier tokens rather than grepping text, so a
      <see cref="...Foo"> doc reference or a "// uses Foo" comment never
      shows up as a match. Reaches for the same whole-assembly cache as
      `search`. Prefer this over `search` when you want "who actually
      calls/uses this" rather than "who mentions this anywhere".
      First call ever on a machine restores the Roslyn NuGet package —
      a one-time cost (shared across all assemblies, not per-call).

  All subcommands print the decompiled file or directory's temp path to
  stderr. Read that directly (with a bounded line range) if you need more
  than what the subcommand printed — don't re-run against the same type or
  assembly to get more, and don't follow up by also `Read`-ing the whole
  temp file/directory for content you already saw.
EOF
}

require_dnx_ilspycmd() {
  if ! dnx ilspycmd -- --version >/dev/null 2>&1; then
    echo "error: 'dnx ilspycmd' is not working. Fall back to 'which ilspycmd' / a global tool install (see SKILL.md)." >&2
    exit 1
  fi
}

# A fingerprint of resolved-path+size+mtime (not file content — checksumming
# a large DLL is wasted work). size+mtime means a rebuilt assembly at the
# same path invalidates its cache entry instead of silently searching stale
# decompiled source. The resolved path is folded in too, via a checksum, so
# two different DLLs that happen to share a basename (e.g. Newtonsoft.Json.dll
# from two different NuGet package versions, or two different projects) never
# collide on the same cache entry even in the unlikely case their size and
# mtime also happen to match.
file_fingerprint() {
  local f="$1"
  local abs path_sum
  abs="$(cd "$(dirname "$f")" 2>/dev/null && pwd)/$(basename "$f")"
  path_sum="$(printf '%s' "$abs" | cksum | awk '{print $1}')"
  { stat -f '%z-%m' "$f" 2>/dev/null || stat -c '%s-%Y' "$f" 2>/dev/null; printf -- '-%s' "$path_sum"; } \
    | tr -c 'a-zA-Z0-9' '_'
}

# Sweep cache entries older than CACHE_MAX_AGE_DAYS. Cheap (shallow, one level
# deep) and run opportunistically on every invocation so the cache doesn't
# grow unbounded on a machine that's been decompiling things for months.
prune_stale_cache() {
  local root="${TMPDIR:-/tmp}/ilspy-find-cache"
  [ -d "$root" ] || return 0
  find "$root" -mindepth 1 -maxdepth 1 -mtime "+${CACHE_MAX_AGE_DAYS}" -exec rm -rf {} + 2>/dev/null || true
  find "$root/types" -mindepth 1 -maxdepth 1 -mtime "+${CACHE_MAX_AGE_DAYS}" -exec rm -f {} + 2>/dev/null || true
}

# Investigating one type usually means several grep/peek/api calls in a row —
# every eval transcript shows the same type getting decompiled from scratch
# on each call. Caching by assembly fingerprint + type name means the 2nd+
# call against a type you already looked at is instant instead of repeating
# a multi-second decompile.
decompile_type() {
  local assembly="$1" type_name="$2"
  local cache_root="${TMPDIR:-/tmp}/ilspy-find-cache/types"
  local key
  key="$(basename "$assembly")-$(file_fingerprint "$assembly")-$(printf '%s' "$type_name" | tr -c 'a-zA-Z0-9' '_')"
  local tmp="$cache_root/$key.cs"
  if [ -s "$tmp" ]; then
    echo "# Reusing cached decompile of $type_name at: $tmp" >&2
  else
    mkdir -p "$cache_root"
    dnx ilspycmd -- -t "$type_name" "$assembly" > "$tmp"
    echo "# Full decompiled type saved to: $tmp" >&2
  fi
  printf '%s' "$tmp"
}

# Decompiling a whole assembly (one .cs file per type via -p) takes several
# seconds — real cost, but not conversation tokens, since nothing is printed
# to stdout here. Caching it means a second `search` against the same build
# is instant instead of repeating that wait.
decompile_assembly_cached() {
  local assembly="$1"
  local cache_root="${TMPDIR:-/tmp}/ilspy-find-cache"
  local key
  key="$(basename "$assembly")-$(file_fingerprint "$assembly")"
  local dir="$cache_root/$key"
  if [ -d "$dir" ] && [ -n "$(find "$dir" -name '*.cs' -print -quit 2>/dev/null)" ]; then
    echo "# Reusing cached whole-assembly decompile at: $dir" >&2
  else
    rm -rf "$dir"
    mkdir -p "$dir"
    dnx ilspycmd -- -p -o "$dir" "$assembly" >/dev/null
    echo "# Decompiled whole assembly (one file per type) to: $dir" >&2
  fi
  printf '%s' "$dir"
}

# grep's substring match is the precise default — when you already know
# roughly what the type is called, it returns just the handful of real
# matches. fzf's fuzzy match is looser (subsequence, not substring) and
# matches far more noise on the same query, so it's only used as a fallback
# when grep finds nothing at all — i.e. genuine typo tolerance, not a
# replacement for a precise search. Its -f flag is a non-interactive filter
# (reads stdin, prints matches, exits) so it works fine without a TTY.
list_filter() {
  local input="$1" pattern="$2" out
  out="$(printf '%s\n' "$input" | grep -i -- "$pattern")" && { printf '%s\n' "$out"; return 0; }
  if command -v fzf >/dev/null 2>&1; then
    echo "# No exact substring match for '$pattern' — falling back to fuzzy match:" >&2
    printf '%s\n' "$input" | fzf -f "$pattern"
  else
    return 1
  fi
}

# rg gives the same -n/-C behavior as grep but is noticeably faster on large
# decompiled files; fall back to grep when it's not on PATH. Works against
# either a single file (grep/rg both handle that natively) or a directory
# (rg recurses by default; grep needs -r to do the same).
context_search() {
  local pattern="$1" context="$2" target="$3"
  if command -v rg >/dev/null 2>&1; then
    rg -n -C "$context" -- "$pattern" "$target"
  else
    grep -rn -C "$context" -- "$pattern" "$target"
  fi
}

cap_output() {
  local total=0 line
  while IFS= read -r line; do
    total=$((total + 1))
    if [ "$total" -gt "$MAX_OUTPUT_LINES" ]; then
      echo "# ... output capped at $MAX_OUTPUT_LINES lines. Narrow your search pattern, or read the temp file directly for more." >&2
      return 0
    fi
    printf '%s\n' "$line"
  done
}

prune_stale_cache

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cmd="${1:-}"
case "$cmd" in
  list)
    assembly="${2:?assembly.dll required}"
    pattern="${3:?name-pattern required}"
    require_dnx_ilspycmd
    all_types="$(dnx ilspycmd -- -l c "$assembly")"
    types_out="$(list_filter "$all_types" "$pattern")" || {
      echo "# No type name matched '$pattern'." >&2
      exit 1
    }
    printf '%s\n' "$types_out" | cap_output
    ;;
  grep)
    assembly="${2:?assembly.dll required}"
    type_name="${3:?type-name required}"
    pattern="${4:?search-pattern required}"
    context="${5:-15}"
    require_dnx_ilspycmd
    tmp="$(decompile_type "$assembly" "$type_name")"
    match_out="$(context_search "$pattern" "$context" "$tmp")" || {
      echo "# No match for '$pattern' in $type_name. Full type is at $tmp — read that directly if the method exists under a different name." >&2
      exit 1
    }
    printf '%s\n' "$match_out" | cap_output
    ;;
  peek)
    assembly="${2:?assembly.dll required}"
    type_name="${3:?type-name required}"
    lines="${4:-60}"
    require_dnx_ilspycmd
    tmp="$(decompile_type "$assembly" "$type_name")"
    head -n "$lines" "$tmp"
    ;;
  api)
    assembly="${2:?assembly.dll required}"
    type_name="${3:?type-name required}"
    require_dnx_ilspycmd
    tmp="$(decompile_type "$assembly" "$type_name")"
    grep -nE '^[[:space:]]*(public|protected|internal)[[:space:]]' "$tmp" | cap_output
    ;;
  search)
    assembly="${2:?assembly.dll required}"
    pattern="${3:?search-pattern required}"
    context="${4:-10}"
    require_dnx_ilspycmd
    dir="$(decompile_assembly_cached "$assembly")"
    match_out="$(context_search "$pattern" "$context" "$dir")" || {
      echo "# No match for '$pattern' anywhere in the assembly. Decompiled project is at $dir if you want to search it differently." >&2
      exit 1
    }
    printf '%s\n' "$match_out" | cap_output
    ;;
  refs)
    assembly="${2:?assembly.dll required}"
    ident="${3:?identifier-name required}"
    require_dnx_ilspycmd
    dir="$(decompile_assembly_cached "$assembly")"
    if ! command -v dotnet >/dev/null 2>&1; then
      echo "error: 'dotnet' is required for refs (runs a small Roslyn-based C# app)." >&2
      exit 1
    fi
    refs_out="$(dotnet run "$SCRIPT_DIR/refs.cs" -- "$dir" "$ident" 2>&1)" || {
      echo "$refs_out" >&2
      exit 1
    }
    printf '%s\n' "$refs_out" | cap_output
    ;;
  *)
    usage
    exit 1
    ;;
esac
