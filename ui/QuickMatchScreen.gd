class_name QuickMatchScreen
extends UiScreen
## "Finding a server" screen. Players appear one by one, then `finished` fires.

signal finished
signal cancelled

var _names: Array[String] = []
var _duration: float = 2.6
var _elapsed: float = 0.0
var _done: bool = false
var _status: Label
var _count: Label
var _list: Label
var _cancel: Button


func setup(names: Array[String], duration: float = -1.0) -> void:
    _names = names
    _duration = duration if duration > 0.0 else randf_range(2.0, 3.2)


func _ready() -> void:
    add_bg(UIKit.BG)
    var col := centered_column(560.0, 14)
    _status = UIKit.label("FINDING A SERVER", 44, UIKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
    col.add_child(_status)
    _count = UIKit.label("", 28, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    col.add_child(_count)
    var panel := UIKit.panel(UIKit.PANEL)
    panel.custom_minimum_size = Vector2(0, 250)
    col.add_child(panel)
    _list = UIKit.wrapped("", 22, UIKit.TEXT)
    panel.add_child(_list)
    _cancel = UIKit.button("CANCEL", 24)
    _cancel.pressed.connect(_on_cancel)
    col.add_child(_cancel)
    _cancel.grab_focus()
    _refresh(1)


func _process(delta: float) -> void:
    if _done:
        return
    _elapsed += delta
    var shown := clampi(1 + int(_names.size() * _elapsed / _duration), 1, _names.size())
    _refresh(shown)
    if _elapsed >= _duration:
        _done = true
        _status.text = "SERVER FOUND!"
        _cancel.disabled = true
        await get_tree().create_timer(0.6).timeout
        if is_inside_tree():
            finished.emit()
    else:
        _status.text = "FINDING A SERVER" + ".".repeat(int(_elapsed * 3.0) % 4)


func _refresh(shown: int) -> void:
    _count.text = "Players: %d / %d" % [shown, _names.size()]
    var lines := PackedStringArray()
    for i in shown:
        lines.append("%s %s" % ["*" if i == 0 else "+", _names[i]])
    _list.text = "\n".join(lines)


func _on_cancel() -> void:
    if _done:
        return
    _done = true
    cancelled.emit()
