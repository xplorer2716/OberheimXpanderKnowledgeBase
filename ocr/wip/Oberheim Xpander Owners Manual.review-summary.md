# Summary — full conversion (69/69 pages)

This document accompanies `Oberheim Xpander Owners Manual.reviewed.md`, the final corrected
version of the manual. It documents the method followed, the choices made, and the points that
deserve a targeted human review.

## Execution environment (different from the original instructions)

The instructions (`Oberheim Xpander Owners Manual.agentic-conversion-instructions.md`) assume a
Windows/PowerShell environment (`System.Drawing`). This session runs on Linux: the downscaled
previews and illustration crops were done in **Python + Pillow** (a session script, not
version-controlled — to be recreated if needed, logic equivalent to the documented `.ps1` script).
The existing `.ps1` script (`ocr/convert-pdf-to-text-ocr.ps1`) was not modified.

## Pages processed

- **Pass 1 (skeleton)**: validated directly against the images of printed pages 2, 3, 4 (full
  table of contents, `page-0003.png` to `page-0005.png`). The table of contents read from the
  image is noticeably more detailed than the rough skeleton in the instructions file. Ambiguities
  resolved:
  - "Check It Out" = printed **p.11** (confirmed, not p.13).
  - LFO X = **p.32**, RAMP X = **p.36** (not 33/37).
- **Pass 2 (image-anchored correction)**: all **69 pages** (`page-0001.png` to `page-0069.png`),
  each visually verified against the raw image before correction.
- **Pass 3 (cold re-read)**: the assembled text is clean (sharp scan, little noise on almost all
  pages); the rare passages where a correction could not be confirmed with 100% certainty are
  marked `[?...?]` directly in `reviewed.md` rather than resolved by guesswork — full list below.
  No additional "cold" re-read surfaced any other suspect passage.

## Image index ↔ printed page number correspondence

The offset between the image index (`page-00NN.png`) and the printed page number is **not
constant** across the whole document: full-page plates with no folio (chapter-opening photos and
diagrams) are interspersed and shift the correspondence at every chapter. Every number cited in
`reviewed.md` was individually verified against the visible footer of the corresponding image
(never inferred by calculation).

| Image | Printed page | Image | Printed page | Image | Printed page |
|---|---|---|---|---|---|
| 1 | — (cover) | 24 | 23 | 47 | 47 |
| 2 | — (title page) | 25 | 24 | 48 | 48 |
| 3 | 2 | 26 | 25 | 49 | 49 |
| 4 | 3 | 27 | 26 | 50 | 50 |
| 5 | 4 | 28 | 27 | 51 | 51 |
| 6 | 5 | 29 | 28 | 52 | 52 |
| 7 | — (plate) | 30 | 29 | 53 | — (plate) |
| 8 | 7 | 31 | 30 | 54 | 55 |
| 9 | 8 | 32 | 31 | 55 | 56 |
| 10 | 9 | 33 | 32 | 56 | 57 |
| 11 | — (plate) | 34 | 33 | 57 | 58 |
| 12 | — (plate) | 35 | 34 | 58 | 59 |
| 13 | 11 | 36 | 35 | 59 | — (plate) |
| 14 | 12 | 37 | 36 | 60 | 61 |
| 15 | 13 | 38 | 37 | 61 | 62 |
| 16 | 14 | 39 | 38 | 62 | 63 |
| 17 | — (plate) | 40 | 39 | 63 | 64 |
| 18 | 17 | 41 | 40 *(see note)* | 64 | 65 |
| 19 | 18 | 42 | — (plate) | 65 | 67 |
| 20 | 19 | 43 | 43 *(see note)* | 66 | 68 |
| 21 | — (plate) | 44 | 44 | 67 | 69 |
| 22 | 21 | 45 | 45 | 68 | 70 |
| 23 | 22 | 46 | 46 | 69 | 71 |

**Note (image 41→43)**: the printed number jumps from 40 (image 41, footer-confirmed) to 43
(image 43, footer-confirmed) even though only a single unnumbered plate (image 42) sits between
them — i.e. a gap of 2 in the printed pagination for a single missing image. Both 41→40 and
43→43 are each individually confirmed on the image (not an extrapolation); the cause of the gap
(a blank page not scanned separately, a two-page spread reduced to a single scan...) was not
resolved and does not affect the corrected text itself, only this pagination annotation.

## Illustrations extracted (20)

All downscaled to grayscale, max 1800 px on the long side, optimized PNG (or JPEG q88 for
halftone photos) — each validated by visually reviewing the crop before it was embedded.

| File | Image page | Content |
|---|---|---|
| `p07-front-panel-photo.jpg` | 7 | Full-page photo of the front panel (chapter 1 opener) |
| `p10-hookup-diagram.png` | 10 | Hookup diagram (Mixer/Amp, DSX, MIDI keyboard) |
| `p11-rear-panel-diagram.png` | 11 | Annotated rear panel diagram |
| `p12-front-panel-diagram.png` | 12 | Annotated front panel diagram (5 sections) |
| `p17-programmer-display.jpg` | 17 | Photo of the Programmer display (chapter 2 opener) |
| `p21-single-patch-page-map.png` | 21 | Single Patch Page Map (chapter 3 opener) |
| `p25-vco-waveforms.png` | 25 | VCO waveforms (Sawtooth/Triangle/Pulse) |
| `p27-filter-mode-diagrams.png` | 27 | 8 filter mode diagrams *(re-extracted and downscaled — replaces the 8.7 MB version from an earlier session, for size consistency with the rest)* |
| `p28-filter-pole-comparison.png` | 28 | Comparative graph of filter slopes (1 to 4 poles) |
| `p29-lag-processor-waveform.png` | 29 | Square Wave before/after Lag Processor |
| `p32-adsr-envelope.png` | 31 | ADSR diagram (Delay/Attack/Decay/Sustain/Release) |
| `p34-lfo-waveforms.png` | 34 | LFO waveforms (Triangle/Square/UpSaw/DownSaw/Random/Noise) |
| `p34-lfo-sampling.png` | 34 | Illustration of SAMPLE mode |
| `p36-tracking-generator-graphs.png` | 36 | 2 Tracking Generator graphs (positive / positive-negative) |
| `p37-ramp-rate-diagram.png` | 37 | "Rate equals ramp time" |
| `p42-multi-patch-master-page-map.png` | 42 | Multi Patch/Master Page Map (chapter 4 opener) |
| `p44-pan-diagram.png` | 44 | PAN diagram (stereo headphone / direct outputs) |
| `p47-zones-keyboard-chart.png` | 47 | Keyboard/MIDI note chart 0-127 with OB-8 markers |
| `p53-cassette-mode-panel.png` | 53 | CASSETTE MODE panel (chapter 5 opener) |
| `p59-basic-patch-diagram.png` | 59 | Block diagram "Basic Patch / OBERHEIM" (chapter 6 opener) |

Total size of the `images/` folder: **8.1 MB** (vs. an estimated ~450 MB had the raw 400 DPI
PNGs been kept as-is).

## Passages still uncertain ([?...?])

- **page-0013 (printed p.11), "Master Tune"**: `The tuning range ([?±?]31) covers a
  quarter-tone up or down.` — digits "31" clear, symbol before them ambiguous on the image.
- **page-0023 (printed p.22)**: `we can use [?...?] to connect one module to another` —
  sentence fragment cut off, missing word(s) not visually confirmed.
- **page-0031 (printed p.30), DADR description**: `This has the same [?...?] as if you
  stopped playing the note...` — missing word (likely "effect") not confirmed.
- **page-0040 (printed p.39), Quantized Modulation**: `A [?symbol?] will appear in the
  display to indicate quantization.` — display symbol not legible on the scan.
- **page-0055 (printed p.56)**: `with all your [?machines?]` — partially legible word.
- **page-0052 (printed p.52), GATE +/-**: the "+" and "−" symbols associated with each polarity
  setting were restored by consistency with the section title, without a fully certain visual
  confirmation of the exact glyph (medium confidence, no `[?...?]` marker since it is not very
  ambiguous).
- **page-0069 (printed p.71)**: handwritten annotation added on the paper copy (EWI controller)
  — partially transcribed, two handwritten numeric values not legible with confidence,
  deliberately omitted (marked `[?]`).

Seven points in total, all listed with their page in the `changelog` blocks of `reviewed.md`.

## Structural decisions

- Chapter-opening pages with a decorative layout (title + section-index column, e.g.
  page-0008, page-0018) are reproduced as a **list** under the chapter's H1 rather than as a
  series of fake H2/H3 headings (instructions rule #4).
- Full-page plates with no folio (photos, chapter-opening diagrams, "Front Panel Picture",
  "Rear Panel Diagram", "Cassette Mode", etc.) are attached to the table-of-contents section
  they conceptually belong to, despite the absence of a visible printed number.
- The "Common Transmitter MIDI Controller Assignments" table (printed p.69) is rendered as a
  Markdown table rather than as running text, per instructions rule #5 on tabular data.
- The MIDI default-values table (printed p.51) was also converted to a Markdown table for
  readability, even though it was originally printed as a simple vertical list.
- A correction proposed in an intermediate draft ("Then press the CV/MIDI button...",
  page-0014) was **rejected**: that label is not visible on the image — only "the button under
  the lower display" appears there — correcting it to "CV/MIDI" would have been an invention
  not visually confirmed (absolute rule #1).

## Possible next steps (outside this session's scope)

- Targeted human review of the 7 `[?...?]` passages listed above.
- Decision on whether to move `reviewed.md` and `images/` from `ocr/wip/` to `manuals/` (outside
  the scope of the agentic instructions, a human decision).
- Processing of the two datasheets mentioned in the instructions (`Xpander CEM 3372.md`, title
  "HP Controllable Signal Processor" probably mis-OCR'd) — not covered here.
