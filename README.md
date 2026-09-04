# Oberheim Xpander Knowledge Base

A community-maintained archive of documentation and reference material for the
**Oberheim Xpander** and **Matrix-12** synthesizers: owner's manuals, service
manuals, parts datasheets, and tooling to OCR scanned manuals into searchable
text.

## Contents

- [`manuals/`](manuals/) — Owner's and service manuals (PDF) for the Xpander
  and Matrix-12.
- [`parts/`](parts/) — Datasheets for key components (CEM chips, display,
  DAC, encoders) and reference photos.
- [`newgroups/`](newgroups/) — Reference material sourced from newsgroup
  discussions (e.g. encoder replacement).
- [`ocr/`](ocr/) — PowerShell scripts to OCR scanned PDF manuals into text,
  plus notes on using an LLM to review OCR output against the source scans.

## OCR pipeline

`ocr/setup-ocr-dependencies.ps1` installs the required tools (Tesseract),
and `ocr/convert-pdf-to-text-ocr.ps1` converts a PDF (or a directory of PDFs)
into text, with optional noise filtering and structure recovery. See the
script's inline help (`Get-Help .\convert-pdf-to-text-ocr.ps1 -Full`) for
details, and [`ocr/post-ocr-ia-review-instructions.md`](ocr/post-ocr-ia-review-instructions.md)
for a method to have an AI review OCR output against the scanned page images
without introducing hallucinated corrections.

## Contributing

Contributions of additional manuals, datasheets, corrected OCR text, or
improvements to the tooling are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
Note that some included manufacturer documents (manuals, datasheets) may
carry their own original copyright; they are archived here for personal,
non-commercial, educational reference.
