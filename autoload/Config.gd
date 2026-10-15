extends Node
## Loads res://data/config.json once. No magic numbers elsewhere: read from here.

var data: Dictionary = {}


func _ready() -> void:
    reload()


func reload() -> void:
    var file := FileAccess.open("res://data/config.json", FileAccess.READ)
    if file == null:
        push_error("Config: could not open res://data/config.json")
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        data = parsed
    else:
        push_error("Config: config.json is not a JSON object")


func get_value(key: String, default_value: Variant = null) -> Variant:
    return data.get(key, default_value)
