class_name MatchManager
extends Node
## Owns one match from roster to podium: mode order, state machine, timers, totals.
## Flow: MODE_INTRO -> PLAYING -> ROUND_RESULTS -> INTERMISSION (x3 modes) -> FINAL_RESULTS -> MENU.
## UI listens to the signals below. Modes never talk to the UI or to this class directly.

signal state_changed(new_state: MatchState.State)
signal mode_intro(mode_id: String, index: int, total: int)
signal round_results(mode_id: String, awarded: Dictionary)
signal final_results(standings: Array)
signal round_finished(result: ModeResult)

var state: MatchState.State = MatchState.State.MENU
var rng := RandomNumberGenerator.new()
var registry := ModeRegistry.new()
var scores := ScoreManager.new()

var roster: Array[Player] = []
var picks: Array[Dictionary] = []
var current_index: int = -1
var current_mode: GameMode

## Countdowns the HUD can read each frame.
var phase_time_left: float = 0.0  # intro, results, intermission, final results
var round_time_left: float = 0.0  # PLAYING

var _running: bool = false
var _result: ModeResult
var _force_ended: bool = false


func start_match(p_roster: Array[Player], seed_value: int = 0) -> void:
    if _running:
        push_warning("MatchManager: a match is already running")
        return
    _running = true
    roster = p_roster
    rng.seed = seed_value if seed_value != 0 else Time.get_ticks_usec()
    Game.match_seed = rng.seed

    registry.load_from()
    picks = registry.pick_modes(int(Config.get_value("modes_per_match", 3)), rng)
    var ids: Array[int] = []
    for p in roster:
        ids.append(p.player_id)
    scores.reset(ids)
    Events.match_started.emit()

    for i in picks.size():
        current_index = i
        await _run_mode(picks[i])
        if i < picks.size() - 1:
            _set_state(MatchState.State.INTERMISSION)
            await _wait(float(Config.get_value("intermission_seconds", 10)))

    _set_state(MatchState.State.FINAL_RESULTS)
    final_results.emit(scores.standings())
    await _wait(float(Config.get_value("final_results_seconds", 15)))

    _free_roster()
    _running = false
    Events.match_ended.emit()
    _set_state(MatchState.State.MENU)


func _run_mode(pick: Dictionary) -> void:
    # --- MODE_INTRO: load the mode and its map, show the rules card ---
    _set_state(MatchState.State.MODE_INTRO)
    _reset_players()
    var mode_scene: PackedScene = load(pick["scene"])
    current_mode = mode_scene.instantiate() as GameMode
    add_child(current_mode)
    var map_scene: PackedScene = null
    if pick["map"] != "":
        map_scene = load(pick["map"])
    current_mode.setup(roster, map_scene, Config.data.duplicate(true))
    mode_intro.emit(pick["id"], current_index, picks.size())
    await _wait(float(Config.get_value("intro_seconds", 5)))

    # --- PLAYING: the mode runs until it emits `finished` or the timer forces it ---
    _result = null
    _force_ended = false
    round_time_left = float(Config.get_value("round_seconds", 180))
    current_mode.finished.connect(_on_mode_finished, CONNECT_ONE_SHOT)
    _set_state(MatchState.State.PLAYING)
    Events.round_started.emit(pick["id"])
    current_mode.start()
    if _result == null:  # the mode may already have finished inside start()
        await round_finished
    Events.round_ended.emit(pick["id"])

    # --- ROUND_RESULTS: convert the result to points ---
    var awarded := scores.apply(pick["id"], _result)
    _set_state(MatchState.State.ROUND_RESULTS)
    round_results.emit(pick["id"], awarded)
    await _wait(float(Config.get_value("results_seconds", 4)))

    # Take players out of the mode's scene so freeing the mode does not free them.
    _detach_players()
    current_mode.teardown()
    current_mode = null


func _process(delta: float) -> void:
    if state != MatchState.State.PLAYING or current_mode == null or _result != null:
        return
    current_mode.tick(delta)
    round_time_left -= delta
    if round_time_left <= 0.0 and not _force_ended:
        _force_ended = true
        current_mode.force_end()  # the mode must answer with `finished`


func _on_mode_finished(result: ModeResult) -> void:
    _result = result
    round_finished.emit(result)


## Ends the current countdown early (Back to Menu button, debug skip).
func skip_phase() -> void:
    phase_time_left = 0.0


func _wait(seconds: float) -> void:
    phase_time_left = seconds
    while phase_time_left > 0.0:
        await get_tree().process_frame
        phase_time_left -= get_process_delta_time()
    phase_time_left = 0.0


func _set_state(new_state: MatchState.State) -> void:
    state = new_state
    state_changed.emit(new_state)


func _reset_players() -> void:
    for p in roster:
        p.alive = true
        p.team_id = -1
        p.velocity = Vector3.ZERO


func _detach_players() -> void:
    for p in roster:
        if p.get_parent() != null:
            p.get_parent().remove_child(p)


func _free_roster() -> void:
    for p in roster:
        if is_instance_valid(p):
            p.free()
    roster.clear()
