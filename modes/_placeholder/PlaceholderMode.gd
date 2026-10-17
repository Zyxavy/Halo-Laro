class_name PlaceholderMode
extends GameMode
## Throwaway mode for testing the match flow. Finishes after a few seconds with a random ranking.
## To test the round timer instead, raise `fake_round_seconds` above `round_seconds` in config.json.

@export var fake_round_seconds: float = 3.0


func start() -> void:
    get_tree().create_timer(fake_round_seconds).timeout.connect(_finish)


func get_hud_data() -> Dictionary:
    return {"alive": players.size()}


func force_end() -> void:
    _finish()


func _finish() -> void:
    if not is_inside_tree():
        return
    var ids: Array[int] = []
    for p in players:
        ids.append(p.player_id)
    ids.shuffle()
    var result := ModeResult.new()
    result.kind = "placement"
    result.placements = ids
    finished.emit(result)
