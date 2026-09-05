# Instructions agentiques — conversion du Oberheim Xpander Owners Manual

Ce fichier est une déclinaison **spécifique** de la méthodologie générique décrite dans
[`ocr/post-ocr-ia-review-instructions.md`](../post-ocr-ia-review-instructions.md), appliquée
aux données déjà produites pour CE manuel précis. Une IA agentique (Claude Code ou
équivalent) doit pouvoir exécuter ce fichier de bout en bout, de façon autonome, sans
avoir besoin du contexte de la conversation qui l'a produit.

**Objectif final** : produire, dans `ocr/wip/`, la meilleure version Markdown possible du
manuel — texte corrigé, structure fidèle, illustrations extraites et référencées — plus
une synthèse de ce qui a été fait.

## Risque n°1 à neutraliser (rappel)

Un LLM qui « corrige » de l'OCR remplace du bruit par du texte plausible plutôt que par le
texte réel. Sur ce manuel, une valeur numérique inventée (ex: un temps de RELEASE, un
nombre d'octaves, un code d'erreur) est pire qu'une faute laissée telle quelle. **Ne jamais
corriger un mot ou un chiffre sans confirmation visuelle sur l'image de la page.** En cas de
doute, marquer `[?original?]` plutôt qu'inventer.

## Inventaire des données disponibles

```
ocr/wip/
├── Oberheim Xpander Owners Manual.pdf              <- source, 69 pages, 11.5 Mo
├── Oberheim Xpander Owners Manual.md               <- dernier brouillon OCR (avec -CleanImages)
├── Oberheim Xpander Owners Manual.raw1.md          <- brouillon antérieur, conservé pour comparaison
├── images/
│   └── p27-filter-mode-diagrams.png                <- exemple déjà extrait et validé (voir plus bas)
└── Oberheim Xpander Owners Manual_ocr-temp/
    ├── page-0001.png            <- rasterisation brute 400 DPI (source de vérité visuelle)
    ├── page-0001-clean.png      <- version nettoyée (déskew + binarisation Sauvola), utile si le
    │                               contraste du brut gêne la lecture, mais l'ORIGINAL brut reste
    │                               la référence pour juger de la fidélité d'une correction
    ├── page-0001.hocr           <- sortie Tesseract hOCR (mots + confiance + position + taille police)
    ├── page-0001.out / .err     <- logs Tesseract (vides = OK)
    └── ... (× 69 pages, numérotées 0001 à 0069)
```

Les deux brouillons `.md` existants sont des sorties **brutes** du pipeline OCR (script
`ocr/convert-pdf-to-text-ocr.ps1`) : ils contiennent du texte plausible mais non vérifié
visuellement, des faux titres Markdown (lignes de labels de panneau prises pour des `#`/`##`),
et une table de matières non fiable. Ils servent de **point de départ**, pas de référence.

## Glossaire figé (ne jamais "corriger" ces termes)

Repris et complété par rapport au glossaire générique :

```
VCO, VCF, VCA, LFO, ENV, RAMP, TRACK, FM, LAG, MIDI, CV, DSX, DMX, Xpander, Oberheim,
patch, zone, tracking generator, Synthesthesia (nom de section du manuel, jeu de mots
volontaire — ne pas "corriger" en "Synthesis"), DADR, EXTRIG, LFOTRIG, GATED, RETRIG,
RETRIG MODE, LEGATO, EXPO-LINEAR, EQUAL TIME, MISC, ZONES, CHAIN, GATE, CASS,
MASTER MULTI PAGES, SERVICE PAGES, DETUNE, PW, FREQ, RES, MODE, SYNC, KEYBD, LEV 1,
VIB, SWITCH MODE, STORE, CLEAR, X SELECT, PAGE 2, Page Modifier, Programmer,
Single Patch, Multi Patch, VCF/VCA page, CEM3372, CEM3374, CMOS, DAC
```

Si un terme rencontré ressemble à l'un de ceux-ci mais orthographié différemment
(ex: "DADR" OCRisé en "DAOR"), corriger vers la forme figée UNIQUEMENT si l'image le
confirme visuellement.

## Squelette structurel (Passe 1) — déjà dégrossi, à valider avec les images

Un premier passage texte-seul (sans image) a produit ce squelette. Les numéros de page
sont pris sur les marqueurs fiables `===== Page N / 69 =====` (générés par le script, pas
par l'OCR) mais n'ont PAS encore été confirmés contre les images des pages 3-5
(sommaire imprimé). **Étape obligatoire avant toute autre passe** : ouvrir
`page-0003.png`, `page-0004.png`, `page-0005.png` et vérifier/compléter cette arborescence,
en particulier :
- l'entrée "Check It Out" (page 11 selon le sommaire, mais le premier heading détecté par
  l'OCR n'apparaît que page 13 — trancher en regardant l'image) ;
- les sous-niveaux non repris ici (LFO X, RAMP X, Modulation Pages détaillé, Multi Patch
  Pages détaillé, Master Pages détaillé) car noyés dans du bruit de labels de panneau.

```
- Welcome to the Xpander ................................ p.6
- Taming The Beast To Work
  - Plug It In ........................................... p.9
  - Check It Out ......................................... p.11 ou p.13 (à confirmer image)
  - Page Theory .......................................... p.15
  - Knobs And Buttons .................................... p.16
  - Using The Programmer ................................. p.18
  - Getting Back To Square One ........................... p.20
- Single Patch Pages ...................................... p.23
  - ENV X ................................................ p.30
  - LFO X ................................................ p.33 (à valider)
  - TRACK X .............................................. p.35
  - RAMP X ............................................... p.37 (à valider)
- Modulation Pages ......................................... p.39
- Multi Patch Pages ........................................ p.44
  - CV/MIDI .............................................. p.46
  - Master Page .......................................... p.49
- Learning To Love Your Cassette Interface ................. p.55
  - Loading In ........................................... p.56
- Subtractive Synthesis / Basic Programming Concepts ....... p.61
- FM Synthesis ............................................. p.62
- Other Considerations / Modifying The Basic Patch ......... p.63
- Error Messages (annexe) .................................. p.66
- MIDI Controllers ......................................... p.68
- Common Transmitter MIDI Controller Assignments .......... p.69
```

Cette arborescence devient les titres Markdown (`#`/`##`/`###`) du fichier final — figée
une fois validée, elle ne doit plus dériver d'une page à l'autre.

## Passe 2 — Correction ancrée image, page par page

Pour chaque page de 1 à 69 :
- Entrée : `page-{0:D4}.png` (image, source de vérité) + le texte OCR correspondant à
  cette page dans `Oberheim Xpander Owners Manual.md` (repérable par le marqueur
  `===== Page N / 69 =====`).
- Contexte constant à fournir à chaque appel : le glossaire figé ci-dessus + le squelette
  structurel validé.
- **1 appel = 1 à 3 pages**, avec l'image correspondante attachée à chaque appel — jamais
  le document entier d'un coup.
- Chevauchement d'1 page entre chunks pour recoller les paragraphes coupés en bordure,
  avec instruction explicite de ne pas dupliquer la répétition.

Prompt type (identique à la méthodologie générique, adapté au manuel) :

```
You are correcting the OCR of a page from the Oberheim Xpander Owners Manual (1984).
You are given:
- the scanned image of the page (absolute source of truth) — page-{0:D4}.png
- the raw OCR text of this page (contains noise: duplicated glyphs, truncated words,
  false Markdown headings on panel-label rows, e.g. "SPEED WAVE RETRIG amp")

ABSOLUTE RULES:
1. Every corrected word must be visible and legible on the image. If you cannot confirm
   it visually, leave the OCR text as-is and mark it [?original_word?] — never invent a
   plausible replacement.
2. NEVER touch a number, a control range, or a time/voltage value (e.g. "0 to 63",
   "2.5 seconds", "+2.8V") without explicit visual confirmation. When in doubt about a
   digit, mark [?value?] rather than choosing one.
3. Fixed glossary (do not "correct" these terms): {{GLOSSARY}}
4. A line marked #/## is a genuine heading only if it matches the validated structural
   skeleton below. A row of panel labels (e.g. "MOD =KEYBD LAG LEVI VIB") is NOT a
   heading: reformat it as running text or a list.
5. A block of tabular data (Error Messages, MIDI Controller Assignments, filter mode
   list, electrical characteristics) must be rendered as a Markdown table, not as a
   flattened run-on paragraph — but only fill cells you can actually read on the image.
6. If this page contains an illustration (see "Extraction des illustrations" below),
   insert a Markdown image reference at the correct point in the text:
   `![short description](images/pNN-short-slug.png)`, and note it in the changelog.
7. Rejoin an end-of-line hyphenation only if the reassembled word is legible on the image.
8. Output: the corrected text, THEN a ```changelog block: `page:line | "before" -> "after"
   | confidence high/medium`. The [?...?] markers stay in the text, not in the changelog.

Validated structural skeleton: {{SKELETON}}
OCR text of page {{N}}: {{TEXT}}
```

## Passe 3 — Relecture à froid

Une fois les 69 pages assemblées dans l'ordre du squelette validé, relire le résultat
**sans** les images, et lister les passages encore marqués `[?...?]` ou qui semblent
suspects (répétition, non-sens, rupture de continuité) pour révision humaine ciblée.

## Extraction des illustrations

Objectif : des fichiers image autonomes, référencés depuis le Markdown, dans
`ocr/wip/images/` (un fichier par illustration, nommé `pNN-slug.png`, NN = numéro de page
sur 2 chiffres, slug = description courte en kebab-case).

### Pages candidates en pleine page (déjà identifiées, à vérifier visuellement)

Pages marquées "(figure or blank page - not OCRed)" par le pipeline — certaines sont
peut-être réellement blanches, à trancher à l'image :
```
1, 7, 10, 17, 21, 42, 53, 59
```

### Pages avec illustration partielle (texte + figure mêlés)

Repérées lors d'une lecture partielle du texte OCR — liste non exhaustive, l'agent doit
aussi balayer les 69 pages par lui-même :
```
p.8-9   : Rear Panel Diagram / Front Panel Picture (mentionnés au sommaire)
p.25    : formes d'onde Sawtooth / Triangle / Pulse
p.27    : diagrammes des modes de filtre (Low/High/Band Pass, Phase)
p.28    : graphe comparatif des 4 pentes de filtre
p.29    : diagramme "Square Wave before/after Lag Processor"
p.33-34 : formes d'onde LFO (Triangle, Saw, Square, Random...)
p.36    : graphes du Tracking Generator (input positif / positif-négatif)
p.64    : block diagram du "Basic Patch" (mentionné en début de section)
```

### Méthode d'extraction

Aucune coordonnée de bounding-box n'est disponible automatiquement (le hOCR ne
segmente que le texte, pas les figures). Procédure :
1. Regarder `page-{0:D4}.png` (la version **brute**, pas la `-clean`, qui a supprimé les
   traits/cadres et peut avoir dégradé les figures). Ces PNG sont grands (page 27 :
   12806×16667 px — bien plus que ce qu'un DPI 400 sur une page A4/Letter laisserait
   attendre) : la fenêtre de lecture d'image plafonne à 2000×2000, donc pour un simple
   coup d'œil visuel, générer d'abord un aperçu réduit (`Graphics.DrawImage` vers ~1800px
   de côté) avant d'estimer le rectangle — voir l'exemple validé ci-dessous.
2. Estimer visuellement le rectangle de l'illustration en fraction de la page.
   **Une première estimation à l'aveugle est peu fiable** : sur la page 27, une première
   tentative à `(left=0.08, top=0.12, right=0.55, bottom=0.40)` a capturé la mauvaise zone
   (le diagramme "MOD=KEYBD..." au lieu des 8 courbes de réponse de filtre) — toujours
   partir d'un aperçu réduit, jamais des coordonnées à l'aveugle.
3. Découper avec le script d'aide ci-dessous. Exemple **validé visuellement** pour la
   page 27 (les 8 diagrammes Low Pass/High Pass/Band Pass/Notch/Phase/combinaisons,
   colonne de gauche) — adapter les fractions pour chaque nouvelle illustration :

```powershell
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile("ocr\wip\Oberheim Xpander Owners Manual_ocr-temp\page-0027.png")
$left = [int]($src.Width * 0.06); $top = [int]($src.Height * 0.35)
$w    = [int]($src.Width * (0.28-0.06)); $h = [int]($src.Height * (0.91-0.35))
$rect = New-Object Drawing.Rectangle($left, $top, $w, $h)
$bmp  = New-Object Drawing.Bitmap($w, $h)
$g    = [Drawing.Graphics]::FromImage($bmp)
$g.DrawImage($src, (New-Object Drawing.Rectangle(0,0,$w,$h)), $rect, [Drawing.GraphicsUnit]::Pixel)
New-Item -ItemType Directory -Force -Path "ocr\wip\images" | Out-Null
$bmp.Save("ocr\wip\images\p27-filter-mode-diagrams.png", [Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $src.Dispose()
```

4. Vérifier le fichier obtenu — générer un aperçu réduit et le relire — avant de la
   référencer dans le Markdown. `ocr\wip\images\p27-filter-mode-diagrams.png` (8,7 Mo)
   est déjà produit et validé de cette façon ; il peut servir de gabarit de référence.

### Numéros de page imprimés vs. index PDF

Le bas de la page 27 (index PDF) affiche le numéro imprimé "26" ("26 Xpander Owners
Manual - Creative Input/The Xpanded Voice") : le numéro imprimé dans le manuel est donc
décalé de -1 par rapport à l'index PDF/hOCR à cet endroit (pages de garde non numérotées
en tête). Ne pas supposer que ce décalage est constant sur tout le document — le
vérifier localement (pied de page visible sur l'image) à chaque fois qu'un numéro de
page doit être cité dans la synthèse ou la table des matières.

## Assemblage final

Produire dans `ocr/wip/` :
- **`Oberheim Xpander Owners Manual.reviewed.md`** : le fichier final, avec :
  - un court en-tête (source PDF, date de révision, passes appliquées) ;
  - la table des matières validée en haut, sous forme de liste Markdown avec liens
    internes (`[Plug It In](#plug-it-in)`) ;
  - le corps organisé selon le squelette figé (H1/H2/H3), texte corrigé, tableaux pour
    les données tabulaires, illustrations intégrées via `![...](images/pNN-slug.png)` ;
  - les marqueurs `[?...?]` restants pour tout passage encore incertain.
- **`ocr/wip/images/`** : les illustrations extraites.
- **`Oberheim Xpander Owners Manual.review-summary.md`** : synthèse à côté du fichier
  final, contenant au minimum :
  - le nombre de pages traitées et de corrections apportées par passe ;
  - la liste des illustrations extraites (page, fichier, description) ;
  - la liste des passages encore marqués `[?...?]` avec leur page, pour révision humaine
    ciblée ;
  - les décisions structurelles prises (ex: résolution de l'ambiguïté "Check It Out").

## Ce que ce fichier ne couvre pas

- La correction des deux datasheets déjà relues informellement en conversation
  (`Xpander CEM 3372.md` et son titre "HP Controllable Signal Processor" probablement
  mal OCRisé) — à traiter séparément avec la même méthodologie si besoin.
- Le rangement final (déplacer le résultat validé de `ocr/wip/` vers `manuals/`) — décision
  humaine, hors du périmètre de ces instructions.
