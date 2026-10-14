# Technical Architecture

*Philippine Games Randomizer (working title). Godot 4.7.2-stable, 3D, native PC for the MVP, web-ready by design. Draft v0.1.*

## 1. Principles

1. **Modes are plugins.** A new mode never touches match flow or scoring code.
2. **Same code path for humans and bots.** Both feed an input struct into the same character logic.
3. **Everything tunable lives in config**, not in scripts.
4. **Deterministic rules, simple physics.** Gameplay results come from rule checks (distance windows, zones, timers). Physics is for feel only.
5. **Web-ready from Day 1.** Compatibility renderer, low-poly assets, no unsupported features, so porting later is cheap.
6. **Local now, networked later.** Game logic is separated from input and match services so real multiplayer can be added without rewrites.

## 2. Stack and Settings

| Item | Choice |
| --- | --- |
| Engine | Godot **4.7.2-stable** (pinned 2026-10-14; everyone installs this exact version) |
| Language | GDScript (typed where possible) |
| Renderer | **Compatibility** (OpenGL), which is also the web-safe renderer |
| Target (MVP) | Windows native export |
| Target (later) | Web export, then mobile browsers |
| Version control | Git, one owner per scene, small frequent merges |
| Assets | Low-poly CC0 packs plus hand-made props, tracked in `assets/LICENSES.md` |

## 3. Project Structure

```
res://
  autoload/        Game.gd, Config.gd, Events.gd, AudioBus.gd
  core/            match/, scoring/, input/, bots/, ui_framework/
    match/         MatchManager.gd, ModeRegistry.gd, MatchState.gd
    scoring/       ScoreManager.gd, ModeResult.gd
    input/         InputProvider.gd, HumanInput.gd, BotInput.gd
    bots/          BotBase.gd, BotRoster.gd
  characters/      Player.tscn, Player.gd, PlayerRig/, skins/
  modes/
    luksong_baka/  LuksongBakaMode.gd, scenes/, bots/, maps/
    agawan_base/   AgawanBaseMode.gd, scenes/, bots/, maps/
    tumbang_preso/ TumbangPresoMode.gd, scenes/, bots/, maps/
  ui/              MainMenu, QuickMatch, ModeIntro, Hud, Intermission, Podium
  data/            config.json, modes.json, bot_names.json
  assets/          models/, textures/, audio/, LICENSES.md
  tools/           debug overlay, bot-only autoplay
```

Rule: **each mode owns its own folder**. Only `core/` and `autoload/` are shared, and changes there go through the team lead.

## 4. System Overview

```
MainMenu --Quick Match--> MatchService --> MatchManager (state machine)
                                             |
              +------------------------------+--------------------+
              |                              |                    |
         ModeRegistry                   ScoreManager         UI (HUD, intro,
   (draws 3 modes + maps)         (results to points)      intermission, podium)
              |
         GameMode (one active)  <--- Players (human + bots) via InputProvider
```

- **MatchService** (interface): creates a match roster. MVP implementation is `LocalMatchService`, which adds the human plus bots. A later `NetworkMatchService` can replace it.
- **MatchManager** owns the match, the mode order, the intermissions, and the totals.
- **GameMode** runs one round, then returns a `ModeResult`.
- **ScoreManager** turns results into points and keeps standings.

## 5. Match State Machine

| State | Duration | Exit |
| --- | --- | --- |
| `MENU` | until Quick Match | roster ready |
| `FINDING_MATCH` | 2-3 s fake search | roster filled with bots |
| `MODE_INTRO` | 5 s | mode loaded |
| `PLAYING` | 180 s (config) | `GameMode.finished` signal or timer |
| `ROUND_RESULTS` | 4 s | points applied |
| `INTERMISSION` | 10 s | next mode, or `FINAL_RESULTS` after the third |
| `FINAL_RESULTS` | until button or 15 s | back to `MENU` |

The mode list is drawn once at match start: **3 distinct modes** from the registry, each with a random map from its map list.

## 6. Mode Contract

Every mode extends `GameMode` and implements the same interface:

```gdscript
class_name GameMode extends Node

signal finished(result: ModeResult)

var players: Array[Player]
var config: Dictionary

func setup(p_players: Array[Player], p_map: PackedScene, p_config: Dictionary) -> void: pass
func start() -> void: pass          # begin the round
func tick(delta: float) -> void: pass
func get_hud_data() -> Dictionary: return {}   # alive count, wave, team score, ...
func force_end() -> void: pass      # called when the timer expires
func teardown() -> void: pass       # free everything
```

`ModeResult` carries either **placements** or **direct points**:

```gdscript
class_name ModeResult extends RefCounted
var kind: String                    # "placement", "points", or "team"
var placements: Array[int]          # player ids, best first
var points: Dictionary              # player_id -> int (direct points)
var team_of: Dictionary             # player_id -> team id (for team modes)
var winning_team: int = -1
var mvp: int = -1
var stats: Dictionary               # per-player extras (hits, tags, rescues)
```

The `ScoreManager` interprets `kind` using the tables in `data/config.json`. A new mode only has to fill in a `ModeResult`.

**Mode registry** (`data/modes.json`):

```json
{
  "luksong_baka":  { "scene": "res://modes/luksong_baka/LuksongBakaMode.tscn",  "maps": ["...map_01.tscn"] },
  "agawan_base":   { "scene": "res://modes/agawan_base/AgawanBaseMode.tscn",    "maps": ["...map_01.tscn"] },
  "tumbang_preso": { "scene": "res://modes/tumbang_preso/TumbangPresoMode.tscn", "maps": ["...map_01.tscn"] }
}
```

Adding a mode means adding a folder and one JSON entry.

## 7. Players, Input, and Bots

- `Player` is a `CharacterBody3D` with the shared rig, a skin (color or team tint), and an `InputProvider`.
- `InputProvider` returns a small struct each frame: `move: Vector2`, `action_a: bool`, `action_b: bool`, `action_a_pressed` and so on.
  - `HumanInput` reads keyboard or gamepad now and touch controls later (virtual joystick plus two buttons).
  - `BotInput` is driven by a **BotBrain** that writes the same struct.
- `BotBase` provides shared helpers: navigation (`NavigationAgent3D` on a baked navmesh), a simple finite state machine, reaction delay, and one **skill value** (0-1) that scales accuracy and reaction time.
- Each mode supplies its own bot script that extends `BotBase` and reads the mode's data (for example `exit_time` in Agawan Base).
- Because humans and bots use the same input struct, any mode can run **bot-only** for automated testing.

**Rule: modes must be playable with one movement input and at most two actions.** This keeps touch controls feasible later.

## 8. Cameras

- One `CameraRig` scene shared by all modes with presets: *follow* (third person), *high follow* (Agawan Base), and *fixed lane* (Luksong Baka).
- Modes request a preset. They do not build their own cameras.

## 9. Scoring Flow

1. `GameMode` emits `finished(result)`.
2. `MatchManager` passes the result to `ScoreManager.apply(result)`.
3. `ScoreManager` updates `totals[player_id]` and stores the per-round breakdown.
4. The HUD and Podium read totals from `ScoreManager`.
5. After mode 3, standings are sorted. Ties break by best single-round result, then random.

Scoring tables live in config:

```json
{
  "placement_points": [10, 7, 5, 4, 3, 2, 1],
  "team_win_points": 6, "team_mvp_points": 8, "team_loss_points": 2,
  "round_seconds": 180, "intermission_seconds": 10, "intro_seconds": 5,
  "lobby_size": 10, "bot_skill_range": [0.4, 0.9]
}
```

## 10. Events and Communication

- Use **signals**, with a global `Events` autoload only for cross-cutting events (`round_started`, `round_ended`, `player_eliminated`, `score_changed`).
- Modes do **not** call into the UI directly. They expose `get_hud_data()` and emit signals. The HUD reads them.
- No node reaches into a sibling mode's data.

## 11. Randomness

- A single `RandomNumberGenerator` is owned by `MatchManager` and seeded per match. The seed is logged in the debug overlay.
- Same seed gives the same mode order and maps, which makes bugs reproducible.

## 12. Web-Readiness Rules (apply now)

- Use the **Compatibility renderer**.
- Budget: low polygon counts, small textures (power of two, compressed), one directional light, no real-time global illumination, no heavy particles, simple shadows or none.
- Avoid GDExtensions and anything thread-dependent.
- Keep character count and animation cost configurable (`lobby_size`).
- Audio must start after the first user input (a "tap to start" screen later).
- Do an early web export test (around Day 4) to catch problems, even though MVP ships native.

## 13. Naming and Code Conventions

- Files: `PascalCase.gd` for classes, `snake_case` for variables and functions, `UPPER_SNAKE` for constants.
- Type hints on all function signatures.
- One scene, one owner. Mode work stays inside the mode folder.
- No magic numbers: tunables go in `data/config.json` or the mode's config dictionary.

## 14. Git and Workflow

- Branches: `main` (always runnable), `feature/<area>-<name>`. Merge to `main` at least daily.
- `.gitignore` for `.godot/`, exports, and OS files.
- Commit messages say what changed and note **AI-assisted** when it applies. This doubles as the development log the organizers may request.
- Keep `assets/LICENSES.md` updated with every new asset (name, author, link, license, used in).
- A short **daily build check**: launch, play a full 3-mode match, and confirm the podium shows.

## 15. Debug and Test Tools

- **Debug overlay:** FPS, seed, current mode, state, per-player points.
- **Bot-only autoplay:** run a whole match with no human, to test scoring and flow.
- **Mode launcher:** jump straight into any single mode from a debug menu, to speed up per-mode development.
- **Config hot-reload** for balance tweaks without code changes.

## 16. Build and Export (MVP)

1. Install Godot export templates for the pinned version.
2. Create a Windows export preset.
3. Test the exported build on at least one machine that is not a dev machine.
4. Record the demo video from the exported build, not the editor.

## 17. Post-MVP Extension Points

| Future feature | Where it plugs in |
| --- | --- |
| Browse Server and real multiplayer | Replace `LocalMatchService` with `NetworkMatchService`; keep `InputProvider` and `GameMode` contracts |
| Touch controls and web build | `HumanInput` touch implementation; web export preset |
| More modes and maps | New folder plus entry in `modes.json` |
| Patintero and Sipa | New `GameMode` subclasses |
| Leaderboards and accounts | Backend service (for example Supabase) behind a `ScoreService` interface |

## 18. Risks Specific to the Architecture

| Risk | Mitigation |
| --- | --- |
| Shared `core/` becomes a bottleneck | Freeze the interfaces on Day 1, only the lead edits `core/` |
| Mode devs need something from another mode | Put it in `core/` through the lead, never import across mode folders |
| Bots break each mode differently | Shared `BotBase` plus bot-only autoplay for early detection |
| Scene merge conflicts | One owner per scene, small commits, daily merges |
