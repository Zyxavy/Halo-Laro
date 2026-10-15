class_name BotRoster
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
