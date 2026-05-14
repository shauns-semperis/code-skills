# pandoc-docker

Converts documents between formats using pandoc in a Docker container — no local pandoc installation needed.

## When it triggers

Any request to convert, export, or transform documents between formats: "convert to markdown", "export as docx", "turn this into a PDF", "make a Word doc from this", etc.

## Prerequisites

- Docker Desktop installed and running
- Internet access for initial `docker pull pandoc/latex` (~3GB image)

## Supported formats

All pandoc input/output formats are supported. See `references/supported-formats.md` for the full list. Common conversions:

- markdown, docx, html, pdf, epub, latex, rst, plain text, pptx, ipynb

## How it works

1. Pre-flight checks (Docker running, input file exists, format validation)
2. Resolves paths and determines output location
3. Runs `docker run --rm pandoc/latex` with appropriate volume mounts
4. Verifies output and reports the file path

A wrapper script (`scripts/pandoc-docker.sh`) handles MSYS/Git Bash path mangling on Windows automatically.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill instructions and workflow |
| `scripts/pandoc-docker.sh` | Docker wrapper handling MSYS path conversion |
| `references/supported-formats.md` | Full list of pandoc input/output formats and aliases |
| `evals/evals.json` | Test cases for verification |
