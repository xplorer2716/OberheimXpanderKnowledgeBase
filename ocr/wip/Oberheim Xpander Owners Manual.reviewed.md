# Oberheim Xpander — Owners Manual (révisé)

- Source : `Oberheim Xpander Owners Manual.pdf` (69 pages, édition originale, juin 1984, par Daniel Sofer)
- Méthode : voir [`ocr/wip/Oberheim Xpander Owners Manual.agentic-conversion-instructions.md`](Oberheim%20Xpander%20Owners%20Manual.agentic-conversion-instructions.md)
- **État : LOT PILOTE, pages image 1–16 seulement (p. de garde à "Knobs And Buttons", p.14 imprimée).** Les pages 17 à 69 restent à traiter en Passe 2 (voir `review-summary.md`).
- Passes appliquées à ce lot : Passe 1 (squelette, validé sur les images des p.3-5 imprimées = sommaire) + Passe 2 (correction ancrée image) pour les pages image 1 à 16. Passe 3 non requise sur un lot aussi propre (aucune correction disputée).
- Convention de numérotation : les titres ci-dessous citent le **numéro de page imprimé** (bas de page du manuel) quand il existe ; le nom de fichier des images et le changelog utilisent l'**index image/PDF** (`page-00NN.png`, 1 à 69), qui ne coïncide pas toujours avec le numéro imprimé (pages de planches sans folio — voir résumé).

## Table des matières (validée sur les images p.3, p.4, p.5 imprimées)

- [Welcome to the Xpander](#welcome-to-the-xpander) — p.5
- [Taming The Beast ("How Do I Work This?")](#taming-the-beast-how-do-i-work-this) — p.6
  - [Plug It In](#plug-it-in) — p.8 (Power, Sound System, Controller)
  - [Picture This](#picture-this) — p.9 (Hookup Diagram, Rear Panel Diagram, Front Panel Picture)
  - [Check It Out](#check-it-out) — p.11 (Tune It Up, Listen To It)
  - [Page Theory](#page-theory) — p.13 (Primary Pages, Other Pages)
  - [Knobs And Buttons](#knobs-and-buttons) — p.14
- Programmed Xcellence — p.16 *(hors périmètre de ce lot)*
- Creative Input / The Xpanded Voice — p.20 *(hors périmètre de ce lot)*
- Putting It All Together — p.42 *(hors périmètre de ce lot)*
- Save It (A Good Investment) — p.54 *(hors périmètre de ce lot)*
- Synthesthesia — p.60 *(hors périmètre de ce lot)*
- Appendices — p.66 *(hors périmètre de ce lot)*

---

## Welcome to the Xpander

*(page-0006.png, p.5 imprimée)*

The Oberheim Xpander combines major innovations in analog and digital hardware with computer software, resulting in a compact, easy to use instrument with vast capabilities.

Each of the Xpander's six voices are completely independent. They can each have a different sound, and can be operated from different MIDI or Control Voltage based controllers simultaneously.

Many of the Xpander's new features are made possible because of the design of the computers' software, or operating instructions. Many circuits that on earlier synthesizers were made up of transistors, resistors and even integrated circuit chips, have been replaced by computer instructions in the Xpander. This use of computer software instead of electronic hardware results in unprecedented flexibility and sophistication with fewer parts, which means less cost and more reliability.

Because the Xpander has features and capabilities never before available, we recommend that you familiarize yourself with these new functions to get the most out of your Xpander.

Experiment! You'll never know what you'll discover.

```changelog
6:2 | "difterent sound" -> "different sound" | confidence high
6:4 | "results in unprecedented and sophistication with fewer parts" -> "results in unprecedented flexibility and sophistication with fewer parts" | confidence high
6:5 | "these new tunctions" -> "these new functions" | confidence high
```

---

## Taming The Beast ("How Do I Work This?")

![Photo du panneau avant de l'Xpander, page d'ouverture de chapitre](images/p07-front-panel-photo.jpg)

*(page-0007.png, planche pleine page sans folio — photo d'ouverture de chapitre, aucun texte)*

*(page-0008.png, p.7 imprimée — page d'ouverture stylisée : titre du chapitre + index visuel des sections, reproduit ci-dessous tel qu'imprimé, ce n'est pas de la prose courante)*

Index des sections de ce chapitre (tel qu'imprimé sur la page d'ouverture) :

- **8** Plug It In — Power, Sound System, Controller
- **9** Picture This — Hookup Diagram, Rear Panel Diagram, Front Panel Picture
- **11** Check It Out — Tune It Up (Master Tune, Master Transpose, Autotune Calibration), Listen To It (Selecting Patches, Auditioning Multi Patches, Auditioning Single Patches, Running the Xpander From CVs? Read This, Playing Patches)
- **13** Page Theory — Primary Pages, Other Pages
- **14** Knobs And Buttons

```changelog
8:1 | OCR brut fortement désordonné sur cette page décorative ("# Work Th's?")", fragments dupliqués/inversés) -> reconstruit directement depuis l'image (mise en page réelle : titre + colonne d'index) | confidence high
```

### Plug It In

*(page-0009.png, p.8 imprimée)*

You need three things before you can get any sound out of the Xpander:

#### Power
The Xpander can operate on AC power between 100-130 volts or 200-260 volts. Make sure the Xpander is set for the voltage in your location before plugging in the power. On the back of the Xpander, next to the power outlet and power on/off switch, is a recessed switch which selects the operating power range to 100-130 volts ("115") or 200-260 volts ("230").

Remove the red foil cover from the power socket and plug in the power cord to the Xpander and the AC power source.

Turn on the Xpander with the power switch next to the power socket on the back panel. Do the displays on the Xpander light up? Does the power switch light up? If not, check your connections.

#### Sound System
Connect the Xpander to a mixing board, stereo, instrument amplifier, or other sound system using the stereo or mono mixed outputs, for now. (There are also individual voice outputs on the back panel of the Xpander. We'll get into how to use them later. See the **PAN Multi Patch Page**.)

#### Controller
The Xpander needs to be connected to some other device that will tell the Xpander when and what to play. The Xpander can be controlled by anything with MIDI or Control Voltage/Gate Outputs.

To operate the Xpander from a MIDI controller such as an Oberheim OB-8 or Oberheim MIDI Keyboard, connect the controller's MIDI OUT to the Xpander's MIDI IN. When the Xpander is first turned on, it will receive MIDI information on all 16 MIDI channels.

To operate the Xpander using Control Voltages and Gate Outputs from the Oberheim DSX Sequencer or other source, connect the Control Voltage and Gate Outputs of your controller to the six pairs of CV/GATE INPUTS on the back of the Xpander.

```changelog
9:1 | "power on. oft switch" -> "power on/off switch" | confidence high
9:1 | "100-130 volts or 200-260 volts ("230")" -> "100-130 volts ("115") or 200-260 volts ("230")" | confidence high
9:3 | "Turn on the Xpander with the power switch... It not, check" -> "...If not, check" | confidence high
9:4 | "mixed outputs. for now." -> "mixed outputs, for now." | confidence high
9:6 | "When the Xpander is tirst turned on" -> "...first turned on" | confidence high
9:7 | "Gate Qutputs of your controller 10 the six pairs of INPUTS" -> "Gate Outputs of your controller to the six pairs of CV/GATE INPUTS" | confidence high
```

### Picture This

*(page-0010.png, p.9 imprimée)*

#### Hookup Diagram

![Schéma de branchement : Xpander relié à un Mixer/Amp, deux enceintes, un séquenceur DSX et un clavier MIDI](images/p10-hookup-diagram.png)

Labels du schéma (transcription directe de l'image) : Mixer/Amp · CV/Gates Out · DSX Digital Sequencer · MIDI Out · Power In · Audio Out · CV/Gates In · MIDI In · Oberheim Xpander. Le clavier MIDI et les deux boîtes en pointillés (OB-8, DMX Drum Machine) illustrent des sources MIDI alternatives, non câblées sur ce schéma (traits en pointillés).

*(page-0011.png, planche sans folio, à la suite de "Picture This")*

#### Rear Panel Diagram

![Schéma du panneau arrière avec toutes les connexions annotées](images/p11-rear-panel-diagram.png)

Labels du schéma (transcription directe de l'image, confiance haute) :
- **Cassette Interface** — Input/Output for data storage
- **MIDI** — In/Out/Thru; Any voice can be assigned to any channel
- **Memory Protect** — Prevents changing stored patches
- **Advance Chain** — Advances to the next program. When CHAIN is on, advances to the next program in the chain. (Rising edge trigger)
- **Pedal Inputs** — 2 Inputs for Footpedals or Footswitches
- **Trigger Input** — Triggers Envelopes, LFOs, Ramps from Drum Machines, etc. (Switchable polarity)
- **CV/Gate Inputs** — Six pairs; Can be assigned to any voice
- **Direct Outputs** — One for each voice
- **Mixed Outputs** — Stereo and Mono
- **Voltage Select** — 115 or 230 for local power
- **Power Input** — Connect to Grounded Outlet
- **Power Switch** — On/Off

```changelog
11:1 | OCR brut ("Advance Chain... Any voice can be assigned paws ta any channel... 115 or 230 tor local power") -> texte reconstruit label par label depuis l'image | confidence high
```

*(page-0012.png, planche sans folio, correspond à "Front Panel Picture", p.10 selon le sommaire)*

#### Front Panel Picture

![Panneau avant annoté : Master, Programmer, Modulation Source/X Select, Page Modifier, Single/Multi Patch Page Select](images/p12-front-panel-diagram.png)

The Xpander's front panel is divided into five sections:

**Master Section** — This section contains the Master Volume control as well as the Master Page and Tune Page buttons.

**Programmer** — The Programmer is used to select and store patches.

**Modulation Source/X Select** — This row of buttons serves two functions. They are used to select modulation sources (such as Levers or Velocity) and to select between the Envelopes, LFOs, Ramps, or Tracking Generators. The buttons can also be used to set values directly, without turning knobs.

**Page Modifier** — This section is "where the action is," because the controls that operate each page appear here, along with displays showing the name and current value of each control. The buttons in this section are used as on/off switches and to access modulation pages. The LEDs to the left of the buttons show their current function. The knobs are used to change settings.

**Single/Multi Patch Page Select** — The buttons in this section select the desired Single Patch or Multi Patch page. The block diagrams show the available controls and modulations on the different pages. The LEDs adjacent to the buttons show which page is currently selected; the last eight digits of the Programmer section display read out the name of the page currently being displayed.

```changelog
12:1 | OCR brut désordonné (callouts Page Modifier/Modulation Source lus avant Master Section, "Modulation Source/. Select" tronqué, "erators" orphelin de "Generators") -> réordonné et complété depuis l'image, dans l'ordre réel gauche->droite | confidence high
12:4 | "1s where the action 1s." -> "is where the action is." | confidence high
```

### Check It Out

*(page-0013.png, p.11 imprimée)*

#### Tune It Up

Now that you've got the Xpander turned on, let's tune it. Here's how:

Press TUNE PAGE (in the Master Section) to access the tuning controls.

This is how the Xpander operates: press a button for a desired page and the controls for that page appear on the displays in the Page Modifier section.

##### Master Tune
Look at the Page Modifier section. The third knob is the Master Tune control. Turn it to fine tune the pitch of the Xpander. The lower display shows the master pitch: "0" equals A=440Hz, "+" is sharp, and "−" is flat. The tuning range ([?±?]31) covers a quarter-tone up or down.

##### Master Transpose
The sixth knob in the Page Modifier section is the Master Transpose. Turn it to transpose the entire Xpander up or down in semitone steps. You can transpose the Xpander up to two octaves up or three octaves down.

##### Autotune Calibration
The expanded Auto-Tune capabilities of the Xpander are shown on the upper display. Press the button under the "ALL" display to tune all the Xpander functions. Besides the normal oscillator tuning, you'll notice things that have never been tuned on a synthesizer before: pulse width, filter frequency, and resonance. These automatic calibrations keep the filters as well as oscillators in perfect tune, the resonance reliable and square waves square.

Tuning isn't something you should have to do often: once when you turn it on and then maybe once more a little bit later. Tuning everything on the Xpander takes almost a minute to complete, so you can tune just one function instead. Tune the oscillators, for example, by pressing "VCOS" instead of "ALL."

#### Listen To It

There are two kinds of sound programs in the Xpander: Single Patches and Multi Patches. Single Patches store the settings for each sound, while Multi Patches combine six individual Single Patches, along with mix, pan, and transposition into a programmed combination. Let's explore some Multi Patches and listen to some of the sounds that are possible on the Xpander.

##### Selecting Patches
Programs are selected in the Programmer section of the Xpander. On the Programmer display, the left most digit will show "M" for Multi Patches or "S" for Single Patches; the next digits show the patch number and name. If the display shows that you are in Single Patch mode, press the MULTI PATCH button.

Once in the desired mode (Multi), pressing two digits on the Programmer Keypad selects a new Multi Patch.

*(page-0014.png, p.12 imprimée)*

##### Auditioning Multi Patches
Select Multi Patch 40. The programmer display should show "M40 MODULA1" which is the number and name of this multi patch. This patch plays itself, modulating through all sorts of permutations. Some of the other patches in the 40s (M41, M42, etc.) show off some of the richness and flexibility that the Xpander is capable of. Try some of these patches by pressing "41," then "42," etc. You can also advance to the next patch by pressing the "+" or "−" keys.

But you didn't get the Xpander just to be entertained, you got it to *play*. So try some of these very playable patches.

If you are controlling the Xpander from MIDI, try Multi Patches 50 through 59 (M50-M59); if you are controlling the Xpander from CVs and Gates, try Multi Patches 60 through 69 (M60-M69). These patches are identical except that the 50s are programmed for MIDI while the 60s are programmed for CVs. These patches combine sounds in some basic ways. Patches M58 and M59 also incorporate several Split Zones into their programming, so that different sounds will play depending on the notes you play.

##### Auditioning Single Patches
Now that you've explored some of the Multi Patch combinations, let's listen to some of the individual Single Patch sounds. Press the SINGLE PATCH button to select Single Patch mode. Notice the "S" on the left side of the display.

##### Running the Xpander from CVs? Read This
Unlike the Multi Patches which can be programmed individually to MIDI or CVs, all the Single Patches look to a Master Multi Page for their control source. When the Xpander is turned on, it is set to receive notes played on any MIDI channel (Omni mode). If you wish to play the Xpander from CVs, you must change this Master Page setting.

Press the MASTER PAGE button in the Master Section. Then press the button under the lower display of the Page Modifier section. (If the lower display is blank, press the SINGLE PATCH button in the Programmer section.) Now the six knobs will enable you to "dial in" the desired CVs. Select a different CV for each voice.

We'll get more into the Master Multi Page (and all the other ones) later...

##### Playing Patches
In Single Patch mode all voices play one sound. These sounds can be selected by using the Programmer Keypad, the same as in Multi Patch mode. Play the different patches to hear some of the individual sounds of the Xpander. Some of these patches will play themselves just as with the Multi Patches.

```changelog
13:4 | "0" equals A=440Hz." + and" "is flat. The tuming range 31)" -> "0" equals A=440Hz, "+" is sharp, and "−" is flat. The tuning range ([?±?]31)" | confidence medium (symbole avant "31" non identifié avec certitude sur l'image, chiffre "31" lisible)
13:9 | "tune it. instead of "ALL"" -> "VCOS" instead of "ALL."" | confidence high
14:1 | "show oft some of the and flexibility" -> "show off some of the richness and flexibility" | confidence high
14:6 | "It 1s set to receive" -> "it is set to receive" | confidence high
```

### Page Theory

*(page-0015.png, p.13 imprimée)*

With an instrument as sophisticated as the Xpander, it becomes impractical to have an individual control for every function in the synthesizer, because the result would be too many knobs. So the Xpander utilizes six sets of controls, grouped into a system of "pages," to control its various functions. This way, all the controls for one section of the synthesizer are accessible at once in the Page Modifier section of the synthesizer. The name of the selected page is always shown on the right side of the Programmer display.

#### Primary Pages
The functions of the primary pages are also shown on the right side of the panel, and can be accessed immediately by pressing the button associated with each section of the block diagram. There are two kinds of primary pages:

**Single Patch pages** are used to program sounds. Within these pages are the controls for all the parameters of individual sound programs: the oscillators, filter, envelopes, modulations, FM, etc.

The block diagrams on the right side of the front panel show the controls accessed from each Single Patch page. The name of each page is printed in white next to the page selection buttons.

All the functions accessed from Single Patch pages are programmed into a *Single Patch program*.

**Multi Patch pages** control all six voices in tandem. These pages access the functions necessary to control all six voices in a coordinated manner, i.e. the Single Patch assigned to each voice, the control source assigned to each voice (CV or MIDI channel), the stereo mix of the voices, etc.

Multi Patch pages are also chosen with the buttons on the right side of the front panel (while in Multi Patch mode) and the names of the Multi Patch pages appear in grey next to each button. Multi Patch mode is selected with the MULTI PATCH button in the Programmer section on the left side of the panel. All the functions accessed from Multi Patch Pages are programmed into a *Multi Patch program*.

```changelog
15:1 | "a system of to control" -> "a system of "pages," to control" | confidence high
15:2 | "The of the primary pages" -> "The functions of the primary pages" | confidence high
15:6 | "selected with the PATCH button" -> "selected with the MULTI PATCH button" | confidence high
```

### Knobs And Buttons

*(page-0016.png, p.14 imprimée)*

#### Other Pages
There are four other kinds of pages in the Xpander:

**Tune Page** accesses the Master Tune control as well as the extensive Auto-Tune and calibration functions of the Xpander. The Tune Page has its own selection button in the Master Section of the front panel. Pressing TUNE PAGE also resets all sustaining envelopes and ramps, "silencing" the Xpander.

**Master Page** accesses the Cassette Interface for program storage and retrieval, Program Chains, and other general housekeeping functions such as MIDI modes, Single Patch controls and Gate Input polarity. The Master Page also has its own selection button in the Master Section.

**Modulation Pages** exist "behind" any function that can be modulated, such as oscillator frequency, filter resonance, or envelope decay. Press the button under the desired function in the Page Modifier Section (see the "modulation select" LED) to reveal its Modulation Page. To pop back up to the primary page, press the PAGE 2 button.

A dot will appear after a function's name if it is being modulated.

**Page 2** accesses additional functions on most of the Single Patch pages, such as the waveform select on the VCO pages. To access a particular Page 2, press the PAGE 2 button to the left of the knobs. The Page 2 LED will light when displaying any Page 2. Press the PAGE 2 button to return to the primary page from *either* a Page 2 or Modulation Page.

Generally, the names of the controls are on the top display in the Page Modifier Section, while the current setting of each control is on the bottom display. There are exceptions, where switches appear on both top and bottom displays. The buttons adjacent to the displays have multiple functions, which are indicated by the Switch Mode LEDs.

**Controls** generally have a range of 0 to 63. Some can be positive or negative as well. Turn the knob to change the value, or press the button above the knob (Value X) and then press two digits in the X Select Section.

**On/Off Switches** are on when the display is underlined and off when not underlined.

**Either/Or Switches** change name when pressed. These switched are always ON one way or the other, so they are always underlined. These can also be selected by turning the knob below the switch.

```changelog
16:1 | pas de correction nécessaire, page nette | confidence high
```
