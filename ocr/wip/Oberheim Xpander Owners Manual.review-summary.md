# Synthèse — conversion complète (69/69 pages)

Ce document accompagne `Oberheim Xpander Owners Manual.reviewed.md`, la version finale
corrigée du manuel. Il documente la méthode suivie, les choix pris, et les points qui
méritent une relecture humaine ciblée.

## Environnement d'exécution (différent des instructions d'origine)

Les instructions (`Oberheim Xpander Owners Manual.agentic-conversion-instructions.md`) supposent
un environnement Windows/PowerShell (`System.Drawing`). Cette session tourne sous Linux : les
aperçus réduits et les découpes d'illustrations ont été faits en **Python + Pillow** (script de
session non versionné, à recréer si besoin — logique équivalente au script `.ps1` documenté).
Le script `.ps1` existant (`ocr/convert-pdf-to-text-ocr.ps1`) n'a pas été modifié.

## Pages traitées

- **Passe 1 (squelette)** : validée directement sur les images des pages imprimées 2, 3, 4
  (sommaire complet, `page-0003.png` à `page-0005.png`). Le sommaire lu à l'image est
  nettement plus détaillé que le squelette dégrossi du fichier d'instructions. Ambiguïtés
  résolues :
  - "Check It Out" = **p.11** imprimée (confirmé, pas p.13).
  - LFO X = **p.32**, RAMP X = **p.36** (pas 33/37).
- **Passe 2 (correction ancrée image)** : les **69 pages** (`page-0001.png` à `page-0069.png`),
  chacune vérifiée visuellement contre l'image brute avant correction.
- **Passe 3 (relecture à froid)** : le texte assemblé est propre (scan net, peu de bruit sur la
  quasi-totalité des pages) ; les rares passages où une correction n'a pas pu être confirmée à
  100% sont marqués `[?...?]` directement dans `reviewed.md` plutôt que résolus par supposition
  — liste complète ci-dessous. Aucune relecture "à froid" supplémentaire n'a fait remonter
  d'autre passage suspect.

## Correspondance index image ↔ numéro de page imprimé

Le décalage entre l'index image (`page-00NN.png`) et le numéro de page imprimé **n'est pas
constant** sur l'ensemble du document : des planches pleine page sans folio (photos et
diagrammes d'ouverture de chapitre) s'intercalent et décalent la correspondance à chaque
chapitre. Chaque numéro cité dans `reviewed.md` a été vérifié individuellement sur le pied de
page visible de l'image correspondante (jamais déduit par calcul).

| Image | Page imprimée | Image | Page imprimée | Image | Page imprimée |
|---|---|---|---|---|---|
| 1 | — (couverture) | 24 | 23 | 47 | 47 |
| 2 | — (titre) | 25 | 24 | 48 | 48 |
| 3 | 2 | 26 | 25 | 49 | 49 |
| 4 | 3 | 27 | 26 | 50 | 50 |
| 5 | 4 | 28 | 27 | 51 | 51 |
| 6 | 5 | 29 | 28 | 52 | 52 |
| 7 | — (planche) | 30 | 29 | 53 | — (planche) |
| 8 | 7 | 31 | 30 | 54 | 55 |
| 9 | 8 | 32 | 31 | 55 | 56 |
| 10 | 9 | 33 | 32 | 56 | 57 |
| 11 | — (planche) | 34 | 33 | 57 | 58 |
| 12 | — (planche) | 35 | 34 | 58 | 59 |
| 13 | 11 | 36 | 35 | 59 | — (planche) |
| 14 | 12 | 37 | 36 | 60 | 61 |
| 15 | 13 | 38 | 37 | 61 | 62 |
| 16 | 14 | 39 | 38 | 62 | 63 |
| 17 | — (planche) | 40 | 39 | 63 | 64 |
| 18 | 17 | 41 | 40 *(voir note)* | 64 | 65 |
| 19 | 18 | 42 | — (planche) | 65 | 67 |
| 20 | 19 | 43 | 43 *(voir note)* | 66 | 68 |
| 21 | — (planche) | 44 | 44 | 67 | 69 |
| 22 | 21 | 45 | 45 | 68 | 70 |
| 23 | 22 | 46 | 46 | 69 | 71 |

**Note (image 41→43)** : le numéro imprimé passe de 40 (image 41, confirmé au pied de page) à 43
(image 43, confirmé au pied de page) alors qu'une seule planche sans folio (image 42) s'intercale
— soit un saut de 2 dans la pagination imprimée pour une seule image manquante. Les deux valeurs
41→40 et 43→43 sont chacune confirmées individuellement sur l'image (pas une extrapolation) ; la
cause de l'écart (page blanche non numérisée séparément, double page réduite à un seul scan...)
n'a pas été élucidée et n'affecte pas le texte corrigé lui-même, seulement cette annotation de
pagination.

## Illustrations extraites (20)

Toutes réduites en niveaux de gris, 1800 px de côté maximum, PNG optimisé (ou JPEG q88 pour les
photos demi-teintes) — validées par relecture visuelle du recadrage avant intégration.

| Fichier | Page image | Contenu |
|---|---|---|
| `p07-front-panel-photo.jpg` | 7 | Photo pleine page du panneau avant (ouverture chapitre 1) |
| `p10-hookup-diagram.png` | 10 | Schéma de branchement (Mixer/Amp, DSX, clavier MIDI) |
| `p11-rear-panel-diagram.png` | 11 | Schéma du panneau arrière annoté |
| `p12-front-panel-diagram.png` | 12 | Schéma du panneau avant annoté (5 sections) |
| `p17-programmer-display.jpg` | 17 | Photo de l'écran du Programmer (ouverture chapitre 2) |
| `p21-single-patch-page-map.png` | 21 | Single Patch Page Map (ouverture chapitre 3) |
| `p25-vco-waveforms.png` | 25 | Formes d'onde VCO (Sawtooth/Triangle/Pulse) |
| `p27-filter-mode-diagrams.png` | 27 | 8 diagrammes des modes de filtre *(réextrait et réduit — remplace la version 8,7 Mo d'une session précédente, pour cohérence de taille avec le reste)* |
| `p28-filter-pole-comparison.png` | 28 | Graphe comparatif des pentes de filtre (1 à 4 pôles) |
| `p29-lag-processor-waveform.png` | 29 | Square Wave before/after Lag Processor |
| `p32-adsr-envelope.png` | 31 | Diagramme ADSR (Delay/Attack/Decay/Sustain/Release) |
| `p34-lfo-waveforms.png` | 34 | Formes d'onde LFO (Triangle/Square/UpSaw/DownSaw/Random/Noise) |
| `p34-lfo-sampling.png` | 34 | Illustration du mode SAMPLE |
| `p36-tracking-generator-graphs.png` | 36 | 2 graphes Tracking Generator (positif / positif-négatif) |
| `p37-ramp-rate-diagram.png` | 37 | "Rate equals ramp time" |
| `p42-multi-patch-master-page-map.png` | 42 | Multi Patch/Master Page Map (ouverture chapitre 4) |
| `p44-pan-diagram.png` | 44 | Schéma PAN (casque stéréo / sorties directes) |
| `p47-zones-keyboard-chart.png` | 47 | Graphe clavier/notes MIDI 0-127 avec repères OB-8 |
| `p53-cassette-mode-panel.png` | 53 | Panneau CASSETTE MODE (ouverture chapitre 5) |
| `p59-basic-patch-diagram.png` | 59 | Block diagram "Basic Patch / OBERHEIM" (ouverture chapitre 6) |

Taille totale du dossier `images/` : **8,1 Mo** (vs. ~450 Mo estimés si les PNG bruts 400 DPI
avaient été conservés tels quels).

## Passages encore incertains ([?...?])

- **page-0013 (p.11 imprimée), "Master Tune"** : `The tuning range ([?±?]31) covers a
  quarter-tone up or down.` — chiffre "31" net, symbole précédent ambigu sur l'image.
- **page-0023 (p.22 imprimée)** : `we can use [?...?] to connect one module to another` —
  fragment de phrase coupé, mot(s) manquant(s) non confirmés visuellement.
- **page-0031 (p.30 imprimée), description DADR** : `This has the same [?...?] as if you
  stopped playing the note...` — mot manquant (probablement "effect") non confirmé.
- **page-0040 (p.39 imprimée), Quantized Modulation** : `A [?symbole?] will appear in the
  display to indicate quantization.` — symbole d'affichage non lisible sur le scan.
- **page-0055 (p.56 imprimée)** : `with all your [?machines?]` — mot partiellement lisible.
- **page-0052 (p.52 imprimée), GATE +/-** : les symboles "+" et "−" associés à chaque réglage de
  polarité ont été restitués par cohérence avec le titre de section, sans confirmation visuelle
  certaine du glyphe exact (confiance medium, pas de marqueur `[?...?]` car peu ambigu).
- **page-0069 (p.71 imprimée)** : annotation manuscrite ajoutée sur l'exemplaire papier
  (contrôleur EWI) — transcrite partiellement, deux valeurs numériques manuscrites illisibles
  avec confiance, volontairement omises (marquées `[?]`).

Sept points au total, tous listés avec leur page dans les blocs `changelog` de `reviewed.md`.

## Décisions structurelles

- Les pages d'ouverture de chapitre à mise en page décorative (titre + colonne-index des
  sections, ex. page-0008, page-0018) sont reproduites comme une **liste** sous le H1 du
  chapitre plutôt que comme une suite de faux titres H2/H3 (règle n°4 des instructions).
- Les planches pleine page sans folio (photos, schémas d'ouverture de chapitre, "Front Panel
  Picture", "Rear Panel Diagram", "Cassette Mode", etc.) sont rattachées à la section du
  sommaire dont elles font conceptuellement partie, malgré l'absence de numéro imprimé visible.
- Le tableau "Common Transmitter MIDI Controller Assignments" (p.69 imprimée) est rendu en
  tableau Markdown plutôt qu'en texte suivi, conformément à la règle n°5 des instructions sur
  les données tabulaires.
- Le tableau des valeurs par défaut MIDI (p.51 imprimée) a également été converti en tableau
  Markdown pour la lisibilité, bien qu'imprimé à l'origine comme une liste verticale simple.
- Une correction proposée dans un brouillon intermédiaire ("Then press the CV/MIDI button...",
  page-0014) a été **rejetée** : ce libellé n'est pas visible sur l'image, seul "the button
  under the lower display" y figure — corriger vers "CV/MIDI" aurait été une invention non
  confirmée visuellement (règle absolue n°1).

## Suite possible (hors périmètre de cette session)

- Relecture humaine ciblée des 7 passages `[?...?]` listés ci-dessus.
- Décision de déplacer `reviewed.md` et `images/` de `ocr/wip/` vers `manuals/` (hors périmètre
  des instructions agentiques, décision humaine).
- Traitement des deux datasheets mentionnées dans les instructions (`Xpander CEM 3372.md`,
  titre "HP Controllable Signal Processor" probablement mal OCRisé) — non couvert ici.
