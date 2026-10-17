class_name ModeIntroScreen
extends UiScreen
## Shown before each round: round number, mode name, rules, countdown.

var _manager: MatchManager
var _index: int = 0
var _total: int = 3
var _info: Dictionary = {}
var _countdown: Label


func setup(manager: MatchManager, index: int, total: int, info: Dictionary) -> void:
    _manager = manager
    _index = index
    _total = total
    _info = info


func _ready() -> void:
    add_bg(Color(0.07, 0.12, 0.24, 0.93))
    var col := centered_column(780.0, 10)
    col.add_child(UIKit.label("ROUND %d OF %d" % [_index + 1, _total], 26, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(UIKit.label(String(_info.get("name", "???")).to_upper(), 72, UIKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(UIKit.label(String(_info.get("tagline", "")), 28, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(UIKit.spacer(10))
    var panel := UIKit.panel(UIKit.PANEL)
    col.add_child(panel)
    var rules := VBoxContainer.new()
    rules.add_theme_constant_override("separation", 8)
    panel.add_child(rules)
    for rule in _info.get("rules", []):
        rules.add_child(UIKit.wrapped("-  " + String(rule), 22, UIKit.TEXT))
    col.add_child(UIKit.spacer(10))
    _countdown = UIKit.label("", 34, UIKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
    col.add_child(_countdown)


func _process(_delta: float) -> void:
    if _manager != null:
        _countdown.text = "Starting in %d" % maxi(ceili(_manager.phase_time_left), 0)
