class_name UiScreen
extends Control
## Base for the full-screen UI screens. Each screen builds its own nodes in code.
## Usage: var s := SomeScreen.new(); s.setup(...); parent.add_child(s)


func _init() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP


func add_bg(color: Color) -> ColorRect:
    var rect := ColorRect.new()
    rect.color = color
    rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(rect)
    return rect


func centered_column(min_width: float = 640.0, separation: int = 14) -> VBoxContainer:
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var column := VBoxContainer.new()
    column.custom_minimum_size = Vector2(min_width, 0)
    column.add_theme_constant_override("separation", separation)
    center.add_child(column)
    return column
