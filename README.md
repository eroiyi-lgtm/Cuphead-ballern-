# Project Inkwell – Level 1 „Das Schreibtisch-Duell“

Godot 4.3+, 2D auf Parallax-Ebenen, Android und iOS im Querformat. Dieser Stand ist **Phase 2**
aus dem Architekturplan: Segment A „Bücherberg“ und Boss-Phase 1 „Die Audienz“ als spielbare Graybox.

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

Prüft Laufen (520 px/s), Sprunghöhe, variable Sprunghöhe, Jump Buffer, 8-Wege-Zielen, Feuerrate,
Ink-Blob, Schaden/Unverwundbarkeit/Hit-Stop, Tod + Neustart (≤ 500 ms, Musik auf Takt 1),
Arena-Übergang, Telegraphs ≥ 0,5 s, max. 2 Wiederholungen, Treffer in beide Richtungen, Sieg.
Exit-Code = Anzahl Fehler.

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

`tools/build_resources.gd` erzeugt die `.tres`-Startwerte neu (überschreibt nur mit `-- --force`).

## Bewusst noch offen (Phase 3+)

Segmente B–D, Boss-Phasen 2 und 3, handgezeichnete Frames statt Graybox-Polygonen, echte
Big-Band-Stems und Foley statt Platzhalter-Synthese, `paper_warp.gdshader`, Export-Presets
für Android/iOS, Geräte-Playtests (60 fps auf Mittelklasse-Android und iPhone).
