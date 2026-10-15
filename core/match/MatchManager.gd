class_name MatchManager
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
