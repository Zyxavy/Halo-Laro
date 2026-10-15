class_name ModeRegistry
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
