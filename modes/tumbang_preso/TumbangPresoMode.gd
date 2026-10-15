class_name TumbangPresoMode
extends GameMode
## OWNER: Gameplay Dev C
## Spec: "MVP Design Specs and Team Plan", Section 5.
## Keep all work inside modes/tumbang_preso/. Need something in core/? Ask the team lead.


func start() -> void:
    # TODO: set up the round (spawn players, props, timers) and begin.
    pass


func tick(_delta: float) -> void:
    # TODO: rules, win checks, bot updates.
    pass


func get_hud_data() -> Dictionary:
    # TODO: scores, current Taya, timer
    return {}


func force_end() -> void:
    _finish()


func _finish() -> void:
    var result := ModeResult.new()
    result.kind = "placement"
    # TODO: fill result.placements (best first).
    finished.emit(result)
