class_name MatchHud
extends Control
## In-round overlay: mode name, round timer, your points, and the mode's own HUD lines.
## It reads MatchManager every frame and never blocks the mouse.

var _manager: MatchManager
var _mode_name: String = ""
var _timer_label: Label
var _score_label: Label
var _data_label: Label


func setup(manager: MatchManager, mode_name: String) -> void:
    _manager = manager
    _mode_name = mode_name


func _init() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 20)
    add_child(margin)

    var top := HBoxContainer.new()
    top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    margin.add_child(top)

    var left := UIKit.label(_mode_name.to_upper(), 28, UIKit.ACCENT)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(left)

    var middle := VBoxContainer.new()
    middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _timer_label = UIKit.label("", 52, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    middle.add_child(_timer_label)
    _data_label = UIKit.label("", 22, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    middle.add_child(_data_label)
    top.add_child(middle)

    _score_label = UIKit.label("", 30, UIKit.HUMAN_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
    _score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(_score_label)
    UIKit.ignore_mouse(self)


func _process(_delta: float) -> void:
    if _manager == null:
        return
    _timer_label.text = UIKit.fmt_time(_manager.round_time_left)
    _score_label.text = "%d pts" % int(_manager.scores.totals.get(UIKit.HUMAN_ID, 0))
    if _manager.current_mode != null:
        var data := _manager.current_mode.get_hud_data()
        var lines := PackedStringArray()
        for key in data:
            lines.append("%s: %s" % [str(key).capitalize(), str(data[key])])
        _data_label.text = "\n".join(lines)
