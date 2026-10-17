class_name IntermissionScreen
extends UiScreen
## Between rounds: standings so far on the left, next mode and countdown on the right.

var _manager: MatchManager
var _standings: Array = []
var _names: Dictionary = {}
var _next_info: Dictionary = {}
var _round_number: int = 1
var _total_rounds: int = 3
var _countdown: Label


func setup(manager: MatchManager, standings: Array, names: Dictionary, next_info: Dictionary, round_number: int, total_rounds: int) -> void:
    _manager = manager
    _standings = standings
    _names = names
    _next_info = next_info
    _round_number = round_number
    _total_rounds = total_rounds


func _ready() -> void:
    add_bg(UIKit.BG)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 40)
    add_child(margin)
    var split := HBoxContainer.new()
    split.add_theme_constant_override("separation", 30)
    margin.add_child(split)

    # Left: standings
    var left := UIKit.panel(UIKit.PANEL)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    split.add_child(left)
    var lbox := VBoxContainer.new()
    lbox.add_theme_constant_override("separation", 4)
    left.add_child(lbox)
    lbox.add_child(UIKit.label("STANDINGS AFTER ROUND %d OF %d" % [_round_number, _total_rounds], 26, UIKit.ACCENT))
    var widths := [50, 260, 100]
    lbox.add_child(UIKit.table_row(["#", "PLAYER", "POINTS"], widths, 16, UIKit.MUTED))
    for i in _standings.size():
        var id: int = _standings[i]["player_id"]
        lbox.add_child(UIKit.table_row([i + 1, _names.get(id, "Player %d" % id), int(_standings[i]["total"])],
            widths, 22, UIKit.TEXT, id == UIKit.HUMAN_ID))

    # Right: next up
    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.alignment = BoxContainer.ALIGNMENT_CENTER
    right.add_theme_constant_override("separation", 10)
    split.add_child(right)
    right.add_child(UIKit.label("NEXT UP", 24, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    right.add_child(UIKit.label(String(_next_info.get("name", "???")).to_upper(), 56, UIKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
    right.add_child(UIKit.label(String(_next_info.get("tagline", "")), 24, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
    right.add_child(UIKit.spacer(24))
    right.add_child(UIKit.label("STARTING IN", 20, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    _countdown = UIKit.label("", 110, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    right.add_child(_countdown)


func _process(_delta: float) -> void:
    if _manager != null:
        _countdown.text = str(maxi(ceili(_manager.phase_time_left), 0))
