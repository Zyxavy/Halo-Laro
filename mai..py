#!/usr/bin/env python3
"""
Repo skeleton generator for the Philippine Games Randomizer (DOST Game Dev entry).

Usage:
    python bootstrap_repo.py [target_dir] [--git]

Creates the Godot 4.7.2 project skeleton from the Technical Architecture doc:
folders, stub GDScript for the core contracts, config/data files, project docs,
.gitignore/.gitattributes, AGENTS.md for the opencode agent, and templates for
the AI-usage log and asset license sheet.

Existing files are never overwritten. All code here is our own original code.
After generating: open the folder once in Godot 4.7.2 (it will re-save
project.godot and generate .import data), then commit.
"""

import subprocess
import sys
from pathlib import Path

GODOT_VERSION = "4.7.2-stable"

FILES = {}

# --------------------------------------------------------------------------
# Godot project file
# --------------------------------------------------------------------------
FILES["project.godot"] = '''; Engine configuration file.
; Open once in Godot 4.7.2 so it re-saves this file, then commit.

config_version=5

[application]

config/name="Philippine Games Randomizer (working title)"
run/main_scene="res://ui/MainMenu.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[autoload]

Game="*res://autoload/Game.gd"
Config="*res://autoload/Config.gd"
Events="*res://autoload/Events.gd"

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
'''

# --------------------------------------------------------------------------
# Data / config
# --------------------------------------------------------------------------
FILES["data/config.json"] = '''{
  "placement_points": [10, 7, 5, 4, 3, 2, 1],
  "team_win_points": 6,
  "team_mvp_points": 8,
  "team_loss_points": 2,
  "round_seconds": 180,
  "intermission_seconds": 10,
  "intro_seconds": 5,
  "results_seconds": 4,
  "final_results_seconds": 15,
  "modes_per_match": 3,
  "lobby_size": 10,
  "bot_skill_range": [0.4, 0.9]
}
'''

FILES["data/modes.json"] = '''{
  "luksong_baka": {
    "scene": "res://modes/luksong_baka/LuksongBakaMode.tscn",
    "maps": ["res://modes/luksong_baka/maps/Map01.tscn"]
  },
  "agawan_base": {
    "scene": "res://modes/agawan_base/AgawanBaseMode.tscn",
    "maps": ["res://modes/agawan_base/maps/Map01.tscn"]
  },
  "tumbang_preso": {
    "scene": "res://modes/tumbang_preso/TumbangPresoMode.tscn",
    "maps": ["res://modes/tumbang_preso/maps/Map01.tscn"]
  }
}
'''

FILES["data/bot_names.json"] = '''[
  "Juan", "Maria", "Pedro", "Ana", "Jose", "Liza", "Mark", "Grace",
  "Carlo", "Nina", "Ramon", "Bea", "Tomas", "Lea", "Andres", "Joy",
  "Miguel", "Rica", "Luis", "Cora"
]
'''

# --------------------------------------------------------------------------
# Autoloads
# --------------------------------------------------------------------------
FILES["autoload/Config.gd"] = '''extends Node
## Loads res://data/config.json once. No magic numbers elsewhere: read from here.

var data: Dictionary = {}


func _ready() -> void:
    reload()


func reload() -> void:
    var file := FileAccess.open("res://data/config.json", FileAccess.READ)
    if file == null:
        push_error("Config: could not open res://data/config.json")
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        data = parsed
    else:
        push_error("Config: config.json is not a JSON object")


func get_value(key: String, default_value: Variant = null) -> Variant:
    return data.get(key, default_value)
'''

FILES["autoload/Events.gd"] = '''extends Node
## Global signals for cross-cutting events only. Modes never call the UI directly.

signal match_started
signal match_ended
signal round_started(mode_id: String)
signal round_ended(mode_id: String)
signal player_eliminated(player_id: int)
signal score_changed(player_id: int, total: int)
'''

FILES["autoload/Game.gd"] = '''extends Node
## Global game state and input-map setup.

var match_seed: int = 0


func _ready() -> void:
    _ensure_input_actions()


func _ensure_input_actions() -> void:
    var actions := {
        "move_left": [KEY_A, KEY_LEFT],
        "move_right": [KEY_D, KEY_RIGHT],
        "move_forward": [KEY_W, KEY_UP],
        "move_back": [KEY_S, KEY_DOWN],
        "action_a": [KEY_SPACE],
        "action_b": [KEY_E],
    }
    for action in actions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key in actions[action]:
            var event := InputEventKey.new()
            event.physical_keycode = key
            InputMap.action_add_event(action, event)
'''

# --------------------------------------------------------------------------
# core/match
# --------------------------------------------------------------------------
FILES["core/match/GameMode.gd"] = '''class_name GameMode
extends Node
## Base class every mode extends. Frozen contract: do not change without the team lead.
## A mode runs one round, then emits `finished` with a ModeResult.

signal finished(result: ModeResult)

var players: Array[Player] = []
var config: Dictionary = {}
var map_scene: PackedScene


func setup(p_players: Array[Player], p_map: PackedScene, p_config: Dictionary) -> void:
    players = p_players
    map_scene = p_map
    config = p_config


func start() -> void:
    pass


func tick(_delta: float) -> void:
    pass


func get_hud_data() -> Dictionary:
    return {}


func force_end() -> void:
    pass


func teardown() -> void:
    queue_free()
'''

FILES["core/match/MatchState.gd"] = '''class_name MatchState
extends RefCounted

enum State {
    MENU,
    FINDING_MATCH,
    MODE_INTRO,
    PLAYING,
    ROUND_RESULTS,
    INTERMISSION,
    FINAL_RESULTS,
}
'''

FILES["core/match/ModeRegistry.gd"] = '''class_name ModeRegistry
extends RefCounted
## Reads res://data/modes.json and draws N distinct modes, each with a random map.

var modes: Dictionary = {}


func load_from(path: String = "res://data/modes.json") -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("ModeRegistry: cannot open %s" % path)
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        modes = parsed


func pick_modes(count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
    var ids: Array = modes.keys()
    # Fisher-Yates shuffle using the match RNG so a seed reproduces the order.
    for i in range(ids.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var swap: Variant = ids[i]
        ids[i] = ids[j]
        ids[j] = swap
    var picks: Array[Dictionary] = []
    for id in ids.slice(0, mini(count, ids.size())):
        var maps: Array = modes[id].get("maps", [])
        var map_path := ""
        if not maps.is_empty():
            map_path = maps[rng.randi_range(0, maps.size() - 1)]
        picks.append({"id": id, "scene": modes[id]["scene"], "map": map_path})
    return picks
'''

FILES["core/match/MatchManager.gd"] = '''class_name MatchManager
extends Node
## Owns the match: roster, mode order, state machine, intermissions, totals.
## TODO (team lead): implement each state per the Technical Architecture doc, section 5.

signal state_changed(new_state: MatchState.State)

var state: MatchState.State = MatchState.State.MENU
var rng := RandomNumberGenerator.new()
var registry := ModeRegistry.new()
var scores := ScoreManager.new()

var roster: Array[Player] = []
var picks: Array[Dictionary] = []
var current_index: int = -1
var current_mode: GameMode


func start_match(p_roster: Array[Player], seed_value: int = 0) -> void:
    roster = p_roster
    rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
    Game.match_seed = rng.seed
    registry.load_from()
    picks = registry.pick_modes(int(Config.get_value("modes_per_match", 3)), rng)
    var ids: Array[int] = []
    for p in roster:
        ids.append(p.player_id)
    scores.reset(ids)
    current_index = -1
    Events.match_started.emit()
    _next_mode()


func _next_mode() -> void:
    current_index += 1
    if current_index >= picks.size():
        _change_state(MatchState.State.FINAL_RESULTS)
        return
    _change_state(MatchState.State.MODE_INTRO)
    # TODO: instance picks[current_index].scene, call setup(), wait intro, then start().


func _on_mode_finished(result: ModeResult) -> void:
    scores.apply(picks[current_index]["id"], result)
    _change_state(MatchState.State.ROUND_RESULTS)
    # TODO: show results, then INTERMISSION (10 s), then _next_mode().


func _change_state(new_state: MatchState.State) -> void:
    state = new_state
    state_changed.emit(new_state)
'''

# --------------------------------------------------------------------------
# core/scoring
# --------------------------------------------------------------------------
FILES["core/scoring/ModeResult.gd"] = '''class_name ModeResult
extends RefCounted
## What every mode returns. Fill the fields that match `kind`.
##   "placement": placements = player ids, best first
##   "points":    points = {player_id: int}
##   "team":      team_of = {player_id: team_id}, winning_team, mvp

var kind: String = "placement"
var placements: Array[int] = []
var points: Dictionary = {}
var team_of: Dictionary = {}
var winning_team: int = -1
var mvp: int = -1
var stats: Dictionary = {}
'''

FILES["core/scoring/ScoreManager.gd"] = '''class_name ScoreManager
extends RefCounted
## Turns ModeResults into points and keeps standings. All numbers come from config.json.

var totals: Dictionary = {}
var round_history: Array[Dictionary] = []


func reset(player_ids: Array[int]) -> void:
    totals.clear()
    round_history.clear()
    for id in player_ids:
        totals[id] = 0


func apply(mode_id: String, result: ModeResult) -> Dictionary:
    var awarded: Dictionary = {}
    match result.kind:
        "placement":
            var table: Array = Config.get_value("placement_points", [1])
            for i in result.placements.size():
                var slot := mini(i, table.size() - 1)
                awarded[result.placements[i]] = int(table[slot])
        "points":
            for id in result.points:
                awarded[id] = int(result.points[id])
        "team":
            var win_pts := int(Config.get_value("team_win_points", 6))
            var mvp_pts := int(Config.get_value("team_mvp_points", 8))
            var loss_pts := int(Config.get_value("team_loss_points", 2))
            for id in result.team_of:
                if result.team_of[id] == result.winning_team:
                    awarded[id] = mvp_pts if id == result.mvp else win_pts
                else:
                    awarded[id] = loss_pts
    for id in awarded:
        totals[id] = int(totals.get(id, 0)) + int(awarded[id])
        Events.score_changed.emit(id, totals[id])
    round_history.append({"mode_id": mode_id, "awarded": awarded})
    return awarded


func best_round(player_id: int) -> int:
    var best := 0
    for entry in round_history:
        best = maxi(best, int(entry["awarded"].get(player_id, 0)))
    return best


## Highest total first. Tiebreak: best single round. (Final ties: random via MatchManager RNG.)
func standings() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for id in totals:
        rows.append({"player_id": id, "total": totals[id], "best": best_round(id)})
    rows.sort_custom(func(a, b):
        if a["total"] != b["total"]:
            return a["total"] > b["total"]
        return a["best"] > b["best"]
    )
    return rows
'''

# --------------------------------------------------------------------------
# core/input + bots
# --------------------------------------------------------------------------
FILES["core/input/InputProvider.gd"] = '''class_name InputProvider
extends RefCounted
## One movement input and at most two actions, so touch controls stay feasible later.

var move: Vector2 = Vector2.ZERO
var action_a: bool = false
var action_b: bool = false
var action_a_pressed: bool = false
var action_b_pressed: bool = false


func poll(_delta: float) -> void:
    pass
'''

FILES["core/input/HumanInput.gd"] = '''class_name HumanInput
extends InputProvider
## Keyboard now. Touch (virtual joystick + two buttons) comes after the MVP.


func poll(_delta: float) -> void:
    move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    action_a = Input.is_action_pressed("action_a")
    action_b = Input.is_action_pressed("action_b")
    action_a_pressed = Input.is_action_just_pressed("action_a")
    action_b_pressed = Input.is_action_just_pressed("action_b")
'''

FILES["core/input/BotInput.gd"] = '''class_name BotInput
extends InputProvider
## Drives a Player through the same input struct as a human.

var brain: BotBase


func poll(delta: float) -> void:
    if brain == null:
        return
    brain.think(delta)
    move = brain.out_move
    action_a = brain.out_action_a
    action_b = brain.out_action_b
    action_a_pressed = brain.out_action_a_pressed
    action_b_pressed = brain.out_action_b_pressed
'''

FILES["core/bots/BotBase.gd"] = '''class_name BotBase
extends RefCounted
## Shared bot helpers. Each mode extends this in its own bots/ folder.
## `skill` is 0..1 and should scale accuracy and reaction time.

var skill: float = 0.6
var bot_player: Player

var out_move: Vector2 = Vector2.ZERO
var out_action_a: bool = false
var out_action_b: bool = false
var out_action_a_pressed: bool = false
var out_action_b_pressed: bool = false


func think(_delta: float) -> void:
    pass


func reaction_delay() -> float:
    return lerpf(0.6, 0.15, skill)


func aim_error() -> float:
    return lerpf(1.0, 0.1, skill)
'''

FILES["core/bots/BotRoster.gd"] = '''class_name BotRoster
extends RefCounted
## Picks bot names and skill levels for the lobby.


static func pick_names(count: int, rng: RandomNumberGenerator) -> Array[String]:
    var file := FileAccess.open("res://data/bot_names.json", FileAccess.READ)
    var all_names: Array = []
    if file != null:
        var parsed: Variant = JSON.parse_string(file.get_as_text())
        if parsed is Array:
            all_names = parsed
    var picked: Array[String] = []
    for i in count:
        if all_names.is_empty():
            picked.append("Bot %d" % (i + 1))
        else:
            picked.append(all_names[rng.randi_range(0, all_names.size() - 1)])
    return picked


static func random_skill(rng: RandomNumberGenerator) -> float:
    var range_cfg: Array = Config.get_value("bot_skill_range", [0.4, 0.9])
    return rng.randf_range(float(range_cfg[0]), float(range_cfg[1]))
'''

# --------------------------------------------------------------------------
# characters
# --------------------------------------------------------------------------
FILES["characters/Player.gd"] = '''class_name Player
extends CharacterBody3D
## One shared character for humans and bots. Modes may override movement
## (for example Luksong Baka auto-runs) by reading `input` themselves.

@export var move_speed: float = 6.0

var player_id: int = -1
var display_name: String = ""
var team_id: int = -1
var is_bot: bool = false
var alive: bool = true
var input: InputProvider


func _physics_process(delta: float) -> void:
    if input == null or not alive:
        return
    input.poll(delta)
    velocity.x = input.move.x * move_speed
    velocity.z = input.move.y * move_speed
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    move_and_slide()
'''

FILES["characters/Player.tscn"] = '''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://characters/Player.gd" id="1"]

[node name="Player" type="CharacterBody3D"]
script = ExtResource("1")
'''

# --------------------------------------------------------------------------
# modes (one folder per mode, one owner per mode)
# --------------------------------------------------------------------------
MODE_TEMPLATE = '''class_name {cls}
extends GameMode
## OWNER: {owner}
## Spec: "MVP Design Specs and Team Plan", {section}.
## Keep all work inside modes/{folder}/. Need something in core/? Ask the team lead.


func start() -> void:
    # TODO: set up the round (spawn players, props, timers) and begin.
    pass


func tick(_delta: float) -> void:
    # TODO: rules, win checks, bot updates.
    pass


func get_hud_data() -> Dictionary:
    # TODO: {hud_hint}
    return {{}}


func force_end() -> void:
    _finish()


func _finish() -> void:
    var result := ModeResult.new()
    result.kind = "{kind}"
    # TODO: fill {fill}.
    finished.emit(result)
'''

MODES = [
    dict(folder="luksong_baka", cls="LuksongBakaMode", owner="Gameplay Dev A",
         section="Section 3", hud_hint="wave number, alive count, timer",
         kind="points", fill="result.points per the survivor split table"),
    dict(folder="agawan_base", cls="AgawanBaseMode", owner="Gameplay Dev B",
         section="Section 4", hud_hint="team scores, timer, jailed count",
         kind="team", fill="team_of, winning_team and mvp"),
    dict(folder="tumbang_preso", cls="TumbangPresoMode", owner="Gameplay Dev C",
         section="Section 5", hud_hint="scores, current Taya, timer",
         kind="placement", fill="result.placements (best first)"),
]

for m in MODES:
    FILES[f"modes/{m['folder']}/{m['cls']}.gd"] = MODE_TEMPLATE.format(**m)
    FILES[f"modes/{m['folder']}/{m['cls']}.tscn"] = (
        '[gd_scene load_steps=2 format=3]\n\n'
        f'[ext_resource type="Script" path="res://modes/{m["folder"]}/{m["cls"]}.gd" id="1"]\n\n'
        f'[node name="{m["cls"]}" type="Node"]\n'
        'script = ExtResource("1")\n'
    )
    FILES[f"modes/{m['folder']}/maps/Map01.tscn"] = (
        '[gd_scene format=3]\n\n'
        '[node name="Map01" type="Node3D"]\n'
    )
    FILES[f"modes/{m['folder']}/bots/.gitkeep"] = ""
    FILES[f"modes/{m['folder']}/scenes/.gitkeep"] = ""

# --------------------------------------------------------------------------
# UI and tools
# --------------------------------------------------------------------------
FILES["ui/MainMenu.tscn"] = '''[gd_scene format=3]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
'''

FILES["ui/.gitkeep"] = ""
FILES["assets/models/.gitkeep"] = ""
FILES["assets/textures/.gitkeep"] = ""
FILES["assets/audio/.gitkeep"] = ""

FILES["tools/DebugOverlay.gd"] = '''extends CanvasLayer
## Add this scene to a level while developing: FPS and the match seed.

var _label := Label.new()


func _ready() -> void:
    layer = 100
    add_child(_label)


func _process(_delta: float) -> void:
    _label.text = "FPS %d | seed %d" % [Engine.get_frames_per_second(), Game.match_seed]
'''

# --------------------------------------------------------------------------
# Repo hygiene and docs
# --------------------------------------------------------------------------
FILES[".gitignore"] = '''# Godot
.godot/
*.translation

# Builds and exports
/builds/
/export/
*.exe
*.pck
*.zip

# Local-only config (never commit keys or machine paths)
opencode.json
.env

# OS / editor
.DS_Store
Thumbs.db
.vscode/
.idea/
'''

FILES[".gitattributes"] = '''# Normalize line endings
* text=auto eol=lf

# Binary assets via Git LFS (run `git lfs install` once per machine)
*.glb filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text
*.fbx filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
'''

FILES["README.md"] = f'''# Philippine Games Randomizer (working title)

DOST Game Dev Competition entry. A low-poly 3D party game: 3 random Filipino traditional-game
modes per match (Luksong Baka, Agawan Base, Tumbang Preso), single player vs bots for the MVP.

- Engine: **Godot {GODOT_VERSION}** (standard build, GDScript). Everyone uses this exact version.
- Renderer: Compatibility (keeps the later web port cheap).
- Target: native Windows build for the MVP.

## Run
1. Install Godot {GODOT_VERSION} and its export templates.
2. Open this folder (`project.godot`) in Godot and press F5.

## Docs
- Design specs and team plan, and Technical Architecture: shared docs from the team lead.
- Workflow and rules: `docs/WORKFLOW.md`
- AI usage log (required for the disclosure form): `docs/AI_USAGE_LOG.md`
- Asset licenses (required for the disclosure form): `assets/LICENSES.md`
- Decisions: `docs/DECISIONS.md`

## Layout
```
autoload/    global singletons (Game, Config, Events)
core/        match, scoring, input, bots  (team lead edits only)
characters/  shared Player
modes/       one folder per mode, one owner per mode
ui/          menus and HUD
data/        config.json, modes.json, bot_names.json
assets/      models, textures, audio, LICENSES.md
tools/       debug helpers
docs/        workflow, decisions, AI usage log
```
'''

FILES["AGENTS.md"] = '''# Instructions for AI coding agents (opencode and others)

This is a Godot 4.7.2 (GDScript, 3D, Compatibility renderer) project for a competition with strict rules.

## Hard rules
1. **Originality (competition Rule 7):** game logic, mechanics and source code must be the team's own.
   Do not paste code from tutorials, templates or open-source projects that implement core mechanics
   (movement, scoring, bots, mode rules). Explain your approach instead of copying known implementations.
2. **Disclosure (Rule 8):** every AI-assisted change must be logged. After finishing a task, append a row to
   `docs/AI_USAGE_LOG.md` (date, tool/model, what it was used for, files touched) and put
   `AI-assisted:` in the commit message.
3. **Assets (Rule 6):** never add art/audio without a row in `assets/LICENSES.md`
   (name, author, link, license, used in). No unlicensed or unknown-source assets.

## Architecture rules
- Modes are plugins: each mode lives only in `modes/<mode>/` and extends `GameMode`.
  Do not edit `core/` or `autoload/` unless the task says so; ask the team lead instead.
- A mode returns a `ModeResult` (`placement`, `points` or `team`). It never touches the UI or ScoreManager directly.
- Humans and bots use the same `InputProvider` struct. One movement input and at most two actions.
- No magic numbers: tunables go in `data/config.json` or the mode's config dictionary.
- Keep it web-ready: Compatibility renderer only, low-poly assets, no GDExtensions or thread-dependent code.

## Style
- Typed GDScript, `snake_case` functions/variables, `PascalCase` classes, `UPPER_SNAKE` constants.
- One scene, one owner: avoid editing `.tscn` files owned by someone else.
- Small commits; `main` must always launch.
'''

FILES["docs/WORKFLOW.md"] = '''# Team workflow

## Daily rhythm
1. Morning stand-up (15 min): done / doing today / blocked.
2. Work on small branches: `feature/<area>-<name>`. Merge to `main` at least daily. `main` must always launch.
3. Midday integration: merge and fix conflicts while everyone is online.
4. Evening build check: launch, play a full 3-mode match, confirm the podium, run bot-only autoplay.
   Tag the build: `day-N`.

## Rules
- One owner per scene and one folder per mode. Only the team lead edits `core/` and `autoload/`.
- Pull requests reviewed by the team lead; tiny fixes may be self-merged.
- Commit messages say what changed. Add `AI-assisted:` when AI helped.
- Log AI use in `docs/AI_USAGE_LOG.md` and assets in `assets/LICENSES.md` as you go.

## Bug labels
- P0: blocks the demo. P1: should fix. P2: nice to have.

## Milestones
- End of Day 1: interfaces frozen, repo works for everyone, character moves.
- End of Day 2: placeholder mode runs the full flow, menu to podium.
- End of Day 4: all three modes playable with basic bots.
- End of Day 6: first full 3-mode match.
- End of Day 7: FEATURE FREEZE.
- Day 8: P0/P1 bugs only, disclosure sheets complete.
- Day 9: demo-ready build and rehearsal. Day 10: record, edit, submit.
'''

FILES["docs/DECISIONS.md"] = '''# Decision log

| Date | Decision | Why | Who |
|---|---|---|---|
| (fill) | Godot 4.7.2-stable, Compatibility renderer, native Windows build for MVP | Fastest path; organizers accept native; web port stays cheap | Team lead |
'''

FILES["docs/AI_USAGE_LOG.md"] = '''# AI usage log (for the competition disclosure form)

Log every AI-assisted piece of work. The organizers may request prompts, logs or version history.

| Date | Who | Tool / model | Used for | Files / areas touched | Notes |
|---|---|---|---|---|---|
| (fill) | | | | | |
'''

FILES["assets/LICENSES.md"] = '''# Asset licenses (for the competition disclosure form)

Every external asset must be listed. Own work: write "Original (team)".

| Asset / pack | Author | Link | License | Used in | Modified? |
|---|---|---|---|---|---|
| (fill) | | | | | |
'''

FILES["opencode.example.json"] = '''{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "godot": {
      "type": "local",
      "command": ["npx", "-y", "@coding-solo/godot-mcp"],
      "enabled": true,
      "environment": {
        "GODOT_PATH": "C:/path/to/Godot_v4.7.2-stable_win64.exe"
      }
    }
  }
}
'''

FILES[".github/pull_request_template.md"] = '''## What changed
-

## Checklist
- [ ] `main` still launches after this merge
- [ ] Only touched files I own (or agreed with the team lead)
- [ ] AI-assisted? Logged in docs/AI_USAGE_LOG.md
- [ ] New assets? Added to assets/LICENSES.md
'''


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    do_git = "--git" in sys.argv
    target = Path(args[0] if args else "game-repo").resolve()
    created = skipped = 0
    for rel, content in FILES.items():
        path = target / rel
        if path.exists():
            skipped += 1
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")
        created += 1
    print(f"Skeleton at {target}: {created} files created, {skipped} already existed.")
    if do_git and not (target / ".git").exists():
        subprocess.run(["git", "init"], cwd=target, check=False)
    print(f"Next: open in Godot {GODOT_VERSION}, press F5, then commit.")


if __name__ == "__main__":
    main()