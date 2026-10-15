class_name AgawanBaseMode
extends GameMode
## OWNER: Gameplay Dev B
## Spec: "MVP Design Specs and Team Plan", Section 4.
## Keep all work inside modes/agawan_base/. Need something in core/? Ask the team lead.


func start() -> void:
    # TODO: set up the round (spawn players, props, timers) and begin.
    pass


func tick(_delta: float) -> void:
    # TODO: rules, win checks, bot updates.
    pass


func get_hud_data() -> Dictionary:
    # TODO: team scores, timer, jailed count
    return {}


func force_end() -> void:
    _finish()


func _finish() -> void:
    var result := ModeResult.new()
    result.kind = "team"
    # TODO: fill team_of, winning_team and mvp.
    finished.emit(result)
