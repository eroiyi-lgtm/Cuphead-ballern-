# Project Inkwell – Level 1 „Das Schreibtisch-Duell“

Godot 4.3+, 2D auf Parallax-Ebenen, Android und iOS im Querformat. Level 1 ist als **Graybox komplett
spielbar**: vier Run-&-Gun-Segmente ohne Checkpoint und Sir Reginald mit allen drei Phasen.

| Teil | Inhalt |
|---|---|
| A „Bücherberg“ | 3 gestaffelte Buchtürme, 4 Ink-Blobs einzeln |
| B „Lineal-Brücke“ | Lineal in 3 Stücken über dem Tintensee (Sturz = 1 HP + Respawn am Brückenanfang), Pencil-Sprites in 2er-Gruppen |
| C „Uhrwerk“ | 3 Zahnräder (Zähne = Plattformen, 40°/s), Kolben, Blobs springen aus den Zahnrädern |
| D „Kippendes Tintenfass“ | Bodenflut alle 2,5 s, Federhalter-Steg als sicherer Weg, 6 Blobs + 4 Pencils |
| Boss Phase 1 (1100 HP) | Tintenspucke, Federkiel-Erlass, Siegelstempel |
| Boss Phase 2 (1000 HP) | Flut auf der rechten Bodenhälfte, 3 schwebende Bücher; Papierflieger-Staffel, Tintenwelle, Bleistift-Garde |
| Boss Phase 3 (900 HP) | Klecks-Spirale, Federstoß in 3 Bahnen, Rage ab 30 % HP |

## Starten

- Editor: Ordner in Godot 4.3+ öffnen, F5.
- Tastatur: A/D bzw. Pfeile laufen, W/S zielen, Leertaste/K springen, J/X feuern, L/Shift Lock-Aim, Esc Pause.
- Gamepad: Stick, A springen, X/rechter Trigger feuern, RB Lock-Aim, Start Pause.
- Touch: Floating-Joystick links, Feuer rechts unten, Sprung links darüber. Lock-Aim: Feuer halten und
  auf dem Sprung-Button nach unten wischen (Option `lock_mode = "fire_hold"`: Lock beim Feuern).
  Pause: Zwei-Finger-Tap oben. Am Desktop mit F6 einblenden (Maus emuliert Touch).

## Debug (nur Debug-Builds)

F1 Hitboxen · F2 zur Boss-Arena · F3 Boss-Phase überspringen · F4 nächste Attacke erzwingen ·
F5 Pattern-Seed fixieren · F6 Touch-Steuerung · F7 Film-Look aus/an · F8 God-Mode

## Automatischer Test

```
godot --headless --path . --import
godot --headless --path . --fixed-fps 60 res://debug/smoke_test.tscn
```

59 Prüfungen: Bewegungswerte, Jump Buffer, Zielen, Feuerrate, Schaden/Hit-Stop, Tod + Neustart
(≤ 500 ms, Musik auf Takt 1), alle Attacken aller drei Phasen (Vorwarnung ≥ 0,5 s, max. 2
Wiederholungen), Arena-Zustände je Phase, Rage, Stürze mit Respawn, Flut und sichere Plätze, Sieg.
Zum Schluss läuft ein Bot vom Start bis in die Arena. Exit-Code = Anzahl Fehler (ca. 2 min).

## Export

`export_presets.cfg` enthält Android (arm64 + armv7, Vibrations-Recht für Haptik, Immersive Mode)
und iOS (iPhone + iPad). Vor dem ersten Build: Export-Templates in Godot installieren, Paket-ID
`com.example.projectinkwell` durch die eigene ersetzen, Keystore bzw. Apple-Team-ID eintragen.

## Struktur

| Ordner | Rolle | Inhalt |
|---|---|---|
| `autoload/` | A1 | Events (Signal-Bus), Game, InputRouter, AudioDirector, SaveData |
| `actors/player/` | A1 | Pete: Bewegung, Tintenpistole, Mündungsfeuer, Hurtbox |
| `combat/` | A1 | Kollisions-Ebenen, Hitbox/Hurtbox, Projektil-Pool (48 + 160) |
| `ui/touch/`, `ui/hud/` | A1 + A2 | Touch-Steuerung, HP-Karten, Todes-/Siegbildschirm |
| `actors/enemies/` | A3 | Ink-Blob Spark, Pencil-Sprite |
| `actors/bosses/` | A3 | BossBrain (generisch), Sir Reginald, Muster je Attacke |
| `levels/level_01_desk/` | A3 + A2 | Level 1, Parallax-Ebenen 0–5 |
| `fx/` | A2 | `vintage_film.gdshader` (1 PostFX-Pass), `actor_fx.gdshader` (Treffer-Blitz + Tinten-Zerlaufen) |
| `audio/` | A4 | Bus-Layout mit Grammophon-Kette; Musik/SFX sind in Phase 2 synthetisierte Platzhalter |
| `data/` | A1 + A3 | Alle Zahlen als `.tres` – nachjustieren ohne Code |
| `debug/` | A1 | Debug-Overlay, Hitbox-Anzeige, Smoke-Test |

## Grafik

Alle Grafiken sind eigene Zeichnungen im Stil der 1930er (Rubber Hose, Tusche-Outlines, Pie-Cut-Augen),
keine fremden Assets. Sie entstehen als SVG aus `tools/draw_art.py` (`python3 tools/draw_art.py`) und
liegen in `art/`. Pete ist ein Rig (`actors/player/pete_rig.gd`): Kopf, Rumpf, Handschuhe und Schuhe
als Zeichnung, Arme und Beine als Tusche-Schläuche, Bewegung „on twos“ mit 12 Posen pro Sekunde.
`fx/shaders/actor_fx.gdshader` lässt die Linien zittern (Boiling Lines), `paper_warp`-Ersatz für die
Hintergründe ist `fx/shaders/paper_wash.gdshader` (Aquarell-Flecken, entsättigt).
Vor jeder Veröffentlichung trotzdem: Bild- und Marken-Check.

## Noch offen

Handgezeichnete Animationsframes (z. B. für Boss-Attacken) als nächste Stufe über dem Rig, echte Big-Band-Stems und Foley statt
Platzhalter-Synthese, Geräte-Playtests
(60 fps auf Mittelklasse-Android und iPhone, Touch-Gefühl, Lock-Aim-Variante), Tuning der
Schwierigkeit mit 5 externen Testern.
