class_name BotRoster
extends RefCounted
## Picks bot names and skill levels for the lobby.


## Names are unique within a lobby. If more bots are requested than there are names, a number is added.
static func pick_names(count: int, rng: RandomNumberGenerator) -> Array[String]:
    var pool: Array[String] = []
    var file := FileAccess.open("res://data/bot_names.json", FileAccess.READ)
    if file != null:
        var parsed: Variant = JSON.parse_string(file.get_as_text())
        if parsed is Array:
            for n in parsed:
                pool.append(str(n))
    # Fisher-Yates shuffle with the match RNG.
    for i in range(pool.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var swap := pool[i]
        pool[i] = pool[j]
        pool[j] = swap
    var picked: Array[String] = []
    for i in count:
        if i < pool.size():
            picked.append(pool[i])
        elif pool.is_empty():
            picked.append("Bot %d" % (i + 1))
        else:
            picked.append("%s %d" % [pool[i % pool.size()], int(i / pool.size()) + 1])
    return picked


static func random_skill(rng: RandomNumberGenerator) -> float:
    var range_cfg: Array = Config.get_value("bot_skill_range", [0.4, 0.9])
    return rng.randf_range(float(range_cfg[0]), float(range_cfg[1]))
