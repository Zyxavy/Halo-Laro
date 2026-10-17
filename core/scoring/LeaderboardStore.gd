class_name LeaderboardStore
extends RefCounted
## Local leaderboard of the human's best match totals (PVE leaderboard). Saved to user://.

const PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10


static func load_entries() -> Array:
    if not FileAccess.file_exists(PATH):
        return []
    var file := FileAccess.open(PATH, FileAccess.READ)
    if file == null:
        return []
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Array:
        return parsed
    return []


## Adds a result and returns its 1-based rank on the board, or -1 if it did not make the top list.
static func add_entry(player_name: String, total: int) -> int:
    var entries: Array = load_entries()
    var rank := 1
    for e in entries:
        if int(e["total"]) >= total:
            rank += 1
    entries.append({"name": player_name, "total": total, "date": Time.get_date_string_from_system()})
    entries.sort_custom(func(a, b): return int(a["total"]) > int(b["total"]))
    if entries.size() > MAX_ENTRIES:
        entries.resize(MAX_ENTRIES)
    var file := FileAccess.open(PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(entries))
    return rank if rank <= MAX_ENTRIES else -1
