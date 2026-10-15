class_name LuksongBakaMode
extends GameMode
## OWNER: Gameplay Dev A
## Spec: "MVP Design Specs and Team Plan", Section 3.
## Keep all work inside modes/luksong_baka/. Need something in core/? Ask the team lead.


func start() -> void:
    # TODO: set up the round (spawn players, props, timers) and begin.
    pass


func tick(_delta: float) -> void:
    # TODO: rules, win checks, bot updates.
    pass


func get_hud_data() -> Dictionary:
    # TODO: wave number, alive count, timer
    return {}


func force_end() -> void:
    _finish()


func _finish() -> void:
    var result := ModeResult.new()
    result.kind = "points"
    # TODO: fill result.points per the survivor split table.
    finished.emit(result)
