---
name: inkwell-art
description: Stil- und Arbeitsregeln für die Grafik von Project Inkwell (1930er-Rubber-Hose-Cartoon, eigene Figuren). Laden, bevor Figuren, Gegner, Kulissen, Effekte oder der Bildausschnitt geändert oder neu gezeichnet werden.
---

# Project Inkwell – Grafik-Skill

Ziel: das Gefühl eines handgezeichneten 1930er-Kinocartoons, mit **komplett eigenen** Figuren und Motiven.

## Harte Regeln

- **Keine fremden Assets.** Keine Sprites, Bilder, Figuren oder Bosse aus anderen Spielen übernehmen oder nachzeichnen, auch nicht aus GitHub-, Reddit- oder Sprite-Sammlungen. Keine Namen anderer Spiele oder Studios in Prompts für Bildgeneratoren.
- **Pete** hat eine Tinten-blaue Hose, einen Ritterhelm, eine Federspitzen-Nase und ein rotes Stirnband. Rot gehört nur dem Stirnband. Keine roten Shorts, keine runden Ohren, keine Knopfhose (zu nah an einer bekannten Maus-Figur).
- **Rosa** (`#E58BA8`) nur für parierbare Objekte; Level 1 hat kein Parry.
- Externe Assets nur mit geprüfter Lizenz (CC0 bzw. kommerziell mit Namensnennung), dokumentiert in `CREDITS.md` und einer `LICENSE.md` neben den Dateien.

## Stil

| Element | Regel |
|---|---|
| Figuren | Rubber Hose: Arme und Beine als Tusche-Schläuche ohne Ellbogen, Pie-Cut-Augen, weiße Vier-Finger-Handschuhe, Squash & Stretch |
| Linien | Tusche `#1C1F2A`/`#0B0C10`, außen 6–8 px, innen 3–4 px bei 1080p; Figuren zittern über `actor_fx.gdshader` (Boiling Lines, 12 fps) |
| Schattierung | eine Schattenform pro Fläche (unten rechts), Feder-Schraffur mit `hatch()` + `clipPath`, ein Glanzlicht oben links |
| Hintergründe | ohne harte Outlines, Aquarell-Verläufe, entsättigt; `paper_wash.gdshader` auf jeder Hintergrund-Ebene |
| Palette | Pergament `#E9DCC0`, Tinte `#1C1F2A`, Zinnober `#C8402E`, Altgold `#B8913A`, Walnuss `#7A4E2D`, Geschosse `#3B2C5E` mit hellem Kern `#F2E6C9`, Luft `#8FA9A0` |
| Bewegung | „on twos“: 12 Posen pro Sekunde (`floor(t * 12) / 12`), nicht flüssig interpoliert |

## Recherchierte Techniken (eingebaut)

- **Linien-Gewicht:** `weight_copy()` in `tools/draw_art.py` legt eine tintenschwarze, nach unten rechts versetzte Kopie unter jede Figur. Konturen werden auf der Schattenseite dick, auf der Lichtseite dünn (Offset-Outline-Prinzip aus der Inkscape-Praxis). Gilt automatisch für `art/pete`, `art/enemies`, `art/reginald`.
- **Squash & Stretch nach Tempo:** Pete streckt sich beim schnellen Fall, staucht beim Landen (`pete_rig.gd`).
- **Overlapping Action:** Der Kopf schwingt der Bewegung verzögert hinterher, Bewegungen laufen in Bögen.
- **Verjüngte Schläuche:** Arme und Beine sind am Rumpf kräftig und zu Hand und Fuß schlanker (`width_curve`).
- **Studio-Arbeitsweise der 1930er:** mit Tusche auf Papier, digital koloriert, Hintergründe Schicht für Schicht als Aquarell; bei uns `paper_wash.gdshader` und Zonen-Ebenen.

## Bildausschnitt

- Kamera nah dran: `ZOOM_RUN = 1.8`, `ZOOM_ARENA = 1.5` (`levels/level_01_desk/level_01.gd`).
- Boden bei 82 % der Bildhöhe im Run-Teil, 90 % in der Arena; Pete ist ca. 20 % der Bildhöhe groß.
- Die Boss-Arena muss bei `ZOOM_ARENA` komplett ins Bild passen (aktuell 1280 px breit).
- Gegner dürfen nur im sichtbaren Bereich schweben (Pencil-Clamp an die Kamera), nichts greift aus dem Off an.
- Touch-Knöpfe: Feuer Ø 250 px, Sprung Ø 190 px, Joystick-Radius 150 px (bei 1080p).
- Jeder Abschnitt hat eine eigene Fern-Kulisse (`ZoneLayer`), damit sich nichts sichtbar wiederholt.

## Arbeitsablauf

1. Zeichnungen entstehen als SVG in `tools/draw_art.py` (2x-Auflösung, Sprite-Skalierung 0,5; Ursprung der Figuren: Füße unten Mitte).
2. `python3 tools/draw_art.py`, dann `godot --headless --path . --import`.
3. Kontaktbogen der SVGs im Browser (Playwright) prüfen, danach Screenshots im Spiel unter `xvfb-run` mit `--rendering-driver opengl3` rendern und ansehen.
4. `godot --headless --path . --fixed-fps 60 res://debug/smoke_test.tscn` muss grün sein, bevor committet wird.
5. Ehrlich bleiben: Rig-Animation ist kein Bild-für-Bild-Film. Für Filmqualität braucht es einen 2D-Animator; die Vorgaben dafür stehen in dieser Datei.
