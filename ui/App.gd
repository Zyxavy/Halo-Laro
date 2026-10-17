extends Node
## Root scene. Owns the MatchManager and swaps UI screens as the match progresses:
##   Menu -> Quick Match search -> Mode intro -> HUD -> Round results -> Intermission -> ... -> Podium -> Menu

var manager: MatchManager
var ui_layer: CanvasLayer
var screen: Control
var hud: MatchHud

var _pending_roster: Array[Player] = []
var _names: Dictionary = {}  # player_id -> display name, copied before the roster is freed


func _ready() -> void:
    manager = MatchManager.new()
    manager.name = "MatchManager"
    add_child(manager)
    manager.registry.load_from()

    ui_layer = CanvasLayer.new()
    ui_layer.layer = 10
    add_child(ui_layer)

    manager.state_changed.connect(_on_state_changed)
    manager.mode_intro.connect(_on_mode_intro)
    manager.round_results.connect(_on_round_results)
    manager.final_results.connect(_on_final_results)
    _show_menu()


func _unhandled_input(event: InputEvent) -> void:
    # Debug only: F10 skips the current countdown (intro, results, intermission, podium).
    if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F10:
        manager.skip_phase()


# ---------------------------------------------------------------- screen helpers

func _show(new_screen: Control) -> void:
    _clear_hud()
    if screen != null:
        screen.queue_free()
    screen = new_screen
    ui_layer.add_child(new_screen)


func _clear_screen() -> void:
    if screen != null:
        screen.queue_free()
        screen = null


func _clear_hud() -> void:
    if hud != null:
        hud.queue_free()
        hud = null


func _mode_info(mode_id: String) -> Dictionary:
    return manager.registry.modes.get(mode_id, {"name": mode_id})


# ---------------------------------------------------------------- menu and quick match

func _show_menu() -> void:
    var menu := MainMenu.new()
    menu.setup(manager.registry.modes)
    menu.quick_match_pressed.connect(_on_quick_match)
    menu.quit_pressed.connect(func(): get_tree().quit())
    _show(menu)


func _on_quick_match() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    _pending_roster = LocalMatchService.build_roster(int(Config.get_value("lobby_size", 10)), rng, Game.player_name)
    var names: Array[String] = []
    for p in _pending_roster:
        names.append(p.display_name)
    var search := QuickMatchScreen.new()
    search.setup(names)
    search.finished.connect(_on_search_finished)
    search.cancelled.connect(_on_search_cancelled)
    _show(search)


func _on_search_cancelled() -> void:
    for p in _pending_roster:
        p.free()
    _pending_roster = []
    _show_menu()


func _on_search_finished() -> void:
    var roster := _pending_roster
    _pending_roster = []
    _names.clear()
    for p in roster:
        _names[p.player_id] = p.display_name
    manager.start_match(roster)


# ---------------------------------------------------------------- match signals

func _on_state_changed(new_state: MatchState.State) -> void:
    match new_state:
        MatchState.State.PLAYING:
            _clear_screen()
            hud = MatchHud.new()
            hud.setup(manager, String(_mode_info(manager.picks[manager.current_index]["id"]).get("name", "")))
            ui_layer.add_child(hud)
        MatchState.State.INTERMISSION:
            _show_intermission()
        MatchState.State.MENU:
            _show_menu()


func _on_mode_intro(mode_id: String, index: int, total: int) -> void:
    var intro := ModeIntroScreen.new()
    intro.setup(manager, index, total, _mode_info(mode_id))
    _show(intro)


func _on_round_results(mode_id: String, awarded: Dictionary) -> void:
    var results := RoundResultsScreen.new()
    results.setup(String(_mode_info(mode_id).get("name", mode_id)), awarded, manager.scores.totals.duplicate(), _names)
    _show(results)


func _show_intermission() -> void:
    var next_index := manager.current_index + 1
    var next_info := {}
    if next_index < manager.picks.size():
        next_info = _mode_info(manager.picks[next_index]["id"])
    var screen_node := IntermissionScreen.new()
    screen_node.setup(manager, manager.scores.standings(), _names, next_info, next_index, manager.picks.size())
    _show(screen_node)


func _on_final_results(standings: Array) -> void:
    var human_total := 0
    var human_rank := 0
    for i in standings.size():
        if int(standings[i]["player_id"]) == UIKit.HUMAN_ID:
            human_total = int(standings[i]["total"])
            human_rank = i + 1
    var board_rank := LeaderboardStore.add_entry(Game.player_name, human_total)
    var podium := PodiumScreen.new()
    podium.setup(manager, standings, _names, human_rank, board_rank, LeaderboardStore.load_entries())
    podium.back_pressed.connect(manager.skip_phase)
    _show(podium)
