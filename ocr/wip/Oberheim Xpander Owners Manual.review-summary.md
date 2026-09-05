# Synthèse — lot pilote (pages image 1 à 16)

Ce lot est un **pilote** destiné à valider la méthode avant de traiter les 69 pages. Voir
`Oberheim Xpander Owners Manual.reviewed.md` pour le texte corrigé correspondant.

## Environnement d'exécution (différent des instructions d'origine)

Les instructions (`Oberheim Xpander Owners Manual.agentic-conversion-instructions.md`) supposent
un environnement Windows/PowerShell (`System.Drawing`). Cette session tourne sous Linux : les
aperçus réduits et les découpes d'illustrations ont été refaits en **Python + Pillow**
(script `img_tools.py`, non versionné — utilitaire de session dans le scratchpad, à recréer si besoin).
Aucun changement du côté du script `.ps1` existant (`ocr/convert-pdf-to-text-ocr.ps1`), qui reste
l'outil de référence pour la conversion PDF→texte initiale sous Windows.

## Pages traitées

- **Passe 1 (squelette)** : validée directement sur les images des pages imprimées 2, 3, 4 (sommaire
  complet, `page-0003.png` à `page-0005.png`). Le sommaire lu à l'image est **beaucoup plus détaillé**
  que le squelette dégrossi du fichier d'instructions (sous-niveaux non listés initialement :
  VCO1/VCO2, VCF/VCA, FM/LAG, ENV X, etc.). Les ambiguïtés signalées dans les instructions sont
  résolues :
  - "Check It Out" = **p.11** imprimée (confirmé, pas p.13).
  - LFO X = **p.32** (pas p.33), RAMP X = **p.36** (pas p.37) — visibles sur le sommaire p.3 imprimée.
- **Passe 2 (correction ancrée image)** : pages image 1 à 16 (couverture, page de titre, sommaire,
  "Welcome to the Xpander", chapitre "Taming The Beast" jusqu'au début de "Knobs And Buttons").
  11 appels de correction, chevauchement d'1 page entre lots.
- **Passe 3 (relecture à froid)** : non jugée nécessaire sur ce lot — texte source net (bon scan),
  une seule incertitude relevée (voir plus bas).

## Correspondance index image ↔ numéro de page imprimé (vérifiée pied de page, pages 1 à 16)

| Image | Contenu | Page imprimée |
|---|---|---|
| page-0001.png | Couverture (photo) | — (non numérotée) |
| page-0002.png | Page de titre / mentions légales | — (non numérotée) |
| page-0003.png | Sommaire (1/3) | 2 |
| page-0004.png | Sommaire (2/3) | 3 |
| page-0005.png | Sommaire (3/3) | 4 |
| page-0006.png | Welcome to the Xpander | 5 |
| page-0007.png | Photo panneau avant (ouverture chapitre) | — (planche sans folio) |
| page-0008.png | "Taming The Beast" + index visuel du chapitre | 7 |
| page-0009.png | Plug It In | 8 |
| page-0010.png | Picture This / Hookup Diagram | 9 |
| page-0011.png | Rear Panel Diagram | — (planche sans folio) |
| page-0012.png | Front Panel Picture (schéma annoté) | — (planche sans folio) |
| page-0013.png | Check It Out / Tune It Up / Listen To It (début) | 11 |
| page-0014.png | Listen To It (suite : Auditioning..., Playing Patches) | 12 |
| page-0015.png | Page Theory / Primary Pages | 13 |
| page-0016.png | Other Pages / Knobs And Buttons | 14 |

**Le décalage index-image = page_imprimée + 1 n'est PAS constant** : il tient de l'image 3 à l'image 6,
puis 3 planches sans folio (images 7, 11, 12) s'intercalent et absorbent le décalage. Confirmé
uniquement en lisant le pied de page réel de chaque image (pas d'hypothèse arithmétique) —
conformément à la mise en garde du fichier d'instructions.

## Illustrations extraites (4)

| Fichier | Page image | Contenu | Taille |
|---|---|---|---|
| `images/p07-front-panel-photo.jpg` | 7 | Photo pleine page du panneau avant (ouverture de chapitre) | 675 Ko |
| `images/p10-hookup-diagram.png` | 10 | Schéma de branchement (Mixer/Amp, DSX, clavier MIDI) | 335 Ko |
| `images/p11-rear-panel-diagram.png` | 11 | Schéma du panneau arrière annoté | 249 Ko |
| `images/p12-front-panel-diagram.png` | 12 | Schéma du panneau avant annoté (5 sections) | 665 Ko |

**Point d'attention pour la suite** : ces 4 fichiers ont été réduits (niveaux de gris, max 1800 px de
côté, PNG optimisé / JPEG q88 pour la photo) avant d'être commités — les PNG bruts découpés depuis les
scans 400 DPI pesaient **30 Mo chacun** (RGBA, pleine résolution), ce qui aurait fait gonfler le dépôt
d'environ 450 Mo pour les ~15 illustrations attendues sur les 69 pages. L'illustration déjà présente
`images/p27-filter-mode-diagrams.png` (validée dans une session précédente) pèse encore 8,7 Mo à pleine
résolution — à réduire de la même façon si vous voulez une taille de dépôt cohérente. **Décision à
confirmer avant de lancer le reste du pipeline** : la résolution réduite (1800 px) reste largement
lisible à l'écran mais perd le piqué du scan 400 DPI d'origine.

## Passages encore incertains ([?...?])

- **page-0013 (p.11 imprimée), "Master Tune"** : `The tuning range ([?±?]31) covers a quarter-tone up
  or down.` — le chiffre "31" est net, mais le caractère qui le précède est ambigu sur l'image
  (glyphe fin, pourrait être "±", "/" ou un artefact de mise en page). À trancher par une relecture
  humaine ciblée ou une image mieux résolue de cette zone précise.

## Décisions structurelles

- La page-0008 (p.7 imprimée) est une page d'ouverture de chapitre à mise en page décorative
  (titre + colonne-index des sections), pas de la prose courante : reproduite comme une liste
  d'index sous le H1 du chapitre plutôt que comme une suite de faux titres H2/H3 (règle n°4 des
  instructions).
- "Front Panel Picture" et "Rear Panel Diagram" (TOC p.10 et p.9) correspondent à des planches
  physiquement **sans folio imprimé** (page-0011, page-0012) : rattachées à leur section du sommaire
  malgré l'absence de numéro visible sur la page elle-même.
- Une correction proposée dans un brouillon intermédiaire ("Then press the CV/MIDI button...") a été
  **rejetée** : ce libellé n'est pas visible sur l'image de la page-0014, seul "the button under the
  lower display" y figure — corriger vers "CV/MIDI" aurait été une invention non confirmée
  visuellement (règle absolue n°1).

## Suite proposée

En attente de votre validation sur ce lot avant de poursuivre :
1. Pages image 17 à 69 (Passe 2), par lots de 5-10 pages, avec extraction d'illustrations au fil de l'eau.
2. Trancher la question de la résolution des images (voir ci-dessus) avant d'en générer ~15 de plus.
3. Passe 3 (relecture à froid) sur l'ensemble une fois les 69 pages assemblées.
