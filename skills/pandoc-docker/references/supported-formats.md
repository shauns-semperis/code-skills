# Pandoc Supported Formats

Captured from `pandoc/latex` image. Refresh by running:
```
docker run --rm pandoc/latex --list-input-formats
docker run --rm pandoc/latex --list-output-formats
```

## Input formats

asciidoc, biblatex, bibtex, bits, commonmark, commonmark_x, creole, csljson, csv, djot, docbook, docx, dokuwiki, endnotexml, epub, fb2, gfm, haddock, html, ipynb, jats, jira, json, latex, man, markdown, markdown_github, markdown_mmd, markdown_phpextra, markdown_strict, mdoc, mediawiki, muse, native, odt, opml, org, pod, pptx, ris, rst, rtf, t2t, textile, tikiwiki, tsv, twiki, typst, vimwiki, xlsx, xml

## Output formats

ansi, asciidoc, asciidoc_legacy, asciidoctor, bbcode, bbcode_fluxbb, bbcode_hubzilla, bbcode_phpbb, bbcode_steam, bbcode_xenforo, beamer, biblatex, bibtex, chunkedhtml, commonmark, commonmark_x, context, csljson, djot, docbook, docbook4, docbook5, docx, dokuwiki, dzslides, epub, epub2, epub3, fb2, gfm, haddock, html, html4, html5, icml, ipynb, jats, jats_archiving, jats_articleauthoring, jats_publishing, jira, json, latex, man, markdown, markdown_github, markdown_mmd, markdown_phpextra, markdown_strict, markua, mediawiki, ms, muse, native, odt, opendocument, opml, org, pdf, plain, pptx, revealjs, rst, rtf, s5, slideous, slidy, tei, texinfo, textile, typst, vimdoc, xml, xwiki, zimwiki

## Unsupported extensions that users will try

| Extension | Why it fails | What to tell the user |
|-----------|-------------|----------------------|
| .doc | Old Word binary format — pandoc only supports .docx (Office Open XML) | Re-save as .docx in Word or LibreOffice, then convert |
| .pages | Apple Pages format — not supported | Export as .docx or .pdf from Pages first |
| .wps | WPS Office format — not supported | Export as .docx first |

## Common aliases

Users often say things that don't exactly match pandoc format names. Map these before validating:

| User says | Pandoc format |
|-----------|---------------|
| md | markdown |
| word | docx |
| powerpoint | pptx |
| excel | xlsx (input only) |
| tex | latex |
| text, txt | plain |
| reveal, slides | revealjs |
| notebook, jupyter | ipynb |
| wiki | mediawiki |
| restructuredtext | rst |
