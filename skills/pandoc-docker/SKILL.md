---
name: pandoc-docker
description: Converts documents between formats (docx, markdown, html, pdf, epub, etc.) using pandoc in a Docker container — no local pandoc installation needed. Triggers when the user asks to convert a document, export to a different format, or transform files between markup/document formats. Covers phrases like "convert to markdown", "export as docx", "turn this into a PDF", "make a Word doc from this", or any file format conversion involving documents. Even if the conversion sounds simple, use this skill — it handles Docker volume mounting, path translation, and pandoc flags correctly.
allowed-tools: Bash(docker info), Bash(bash *pandoc-docker.sh run --rm pandoc/latex*), Bash(bash *pandoc-docker.sh run --rm pandoc/core*), Bash(docker pull pandoc/latex), Bash(docker pull pandoc/core)
---

# Document Conversion with Pandoc via Docker

Pandoc is not installed locally — every conversion runs through a disposable `pandoc/latex` Docker container.

All docker commands go through the wrapper script at `scripts/pandoc-docker.sh` (relative to this skill's directory). The wrapper handles MSYS/Git Bash path mangling on Windows. Resolve its absolute path once during pre-flight:

```bash
PANDOC_DOCKER="<skill-dir>/scripts/pandoc-docker.sh"
```

## Core command pattern

```bash
bash "$PANDOC_DOCKER" run --rm -v "<host-dir>:/data" pandoc/latex /data/<input> -t <format> -o /data/<output> [options]
```

When input and output directories differ, use two mounts:

```bash
bash "$PANDOC_DOCKER" run --rm -v "<input-dir>:/input" -v "<output-dir>:/output" pandoc/latex /input/<file> -t <format> -o /output/<file> [options]
```

## Workflow

### 0. Pre-flight checks

**Docker available?** Run `docker info` (suppress stdout, check exit code). Stop if it fails.

**Input file exists?** Verify before mounting — a missing file produces a confusing container error.

**Input format.** Pandoc auto-detects from the file extension — don't specify `-f` unless detection fails. Gotcha: `.doc` (old Word binary) is not supported — only `.docx`. For unrecognized extensions, ask the user.

**Output format.** Map the user's request to a pandoc format name, then confirm it's in the supported outputs list in `references/supported-formats.md`. If unsupported, tell the user immediately.

Output aliases:

| User says | Pandoc format |
|-----------|---------------|
| md | markdown |
| word | docx |
| powerpoint | pptx |
| tex | latex |
| text, txt | plain |
| slides | revealjs |
| notebook, jupyter | ipynb |
| wiki | mediawiki |
| restructuredtext | rst |

### 1. Resolve paths

Resolve relative paths against the current working directory. Docker Desktop on Windows accepts native paths in `-v` mounts.

### 2. Determine output

If the user specifies an output path, use it. Otherwise, place the output next to the input with the same base name and new extension. If the output directory doesn't exist, ask for confirmation before creating it.

| Format   | Extension |
|----------|-----------|
| markdown | .md       |
| docx     | .docx     |
| html     | .html     |
| pdf      | .pdf      |
| epub     | .epub     |
| rst      | .rst      |
| latex    | .tex      |
| plain    | .txt      |

### 3. Build the command

Always pass `-t <format>` explicitly. Pandoc's extension-based auto-detection is unreliable for some extensions (e.g., `.txt` silently defaults to markdown instead of `plain`).

**Markdown output** → also add `--wrap=none` (prevents hard-wrapping at column 72).

**Example — same directory:**
```bash
bash "$PANDOC_DOCKER" run --rm -v "C:/Users/shaun/docs:/data" pandoc/latex /data/report.docx -t markdown -o /data/report.md --wrap=none
```

**Example — different directories:**
```bash
bash "$PANDOC_DOCKER" run --rm -v "C:/Users/shaun/docs:/input" -v "C:/Users/shaun/output:/output" pandoc/latex /input/report.docx -t markdown -o /output/report.md --wrap=none
```

### 4. Run and verify

Run the command, confirm the output file exists, report its path. If the image isn't found, pull it first: `docker pull pandoc/latex`.

## Additional options

| Option | When to use |
|--------|-------------|
| `--standalone` (`-s`) | Complete HTML or LaTeX document (not a fragment) |
| `--toc` | Table of contents requested |
| `--reference-doc=ref.docx` | Apply a Word template |
| `--pdf-engine=xelatex` | Better Unicode/font support in PDF |
| `--extract-media=./media` | Extract embedded images from docx/epub |
| `--shift-heading-level-by=-1` | Heading levels are off |

`--wrap=none` is applied automatically for markdown output — no need to add it manually.

## Embedded images

When converting from formats with embedded images (docx, epub), add `--extract-media`:

```bash
bash "$PANDOC_DOCKER" run --rm -v "C:/Users/shaun/docs:/data" pandoc/latex /data/report.docx -t markdown -o /data/report.md --extract-media=/data/media --wrap=none
```

## Batch conversions

```bash
for f in C:/Users/shaun/docs/*.docx; do
    bash "$PANDOC_DOCKER" run --rm -v "$(dirname "$f"):/data" pandoc/latex "/data/$(basename "$f")" -t markdown -o "/data/$(basename "${f%.docx}.md")" --wrap=none
done
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `pull access denied` | `docker pull pandoc/latex` |
| `openBinaryFile: does not exist` | Check host path exists and is absolute |
| `C:/Program Files/Git/data/...` in error | Use the `scripts/pandoc-docker.sh` wrapper |
| PDF empty or errors | Try `pandoc/extra` for exotic LaTeX packages |
| Garbled Unicode in PDF | Add `--pdf-engine=xelatex` |
