class_name UIKit
extends RefCounted
## Shared look and small helpers for the code-built UI. Change colors here to restyle everything.

const HUMAN_ID := 0
const BG := Color("41463D")            # charcoal-brown
const PANEL := Color("585C54")         # charcoal-brown, lifted
const PANEL_LIGHT := Color("6B6F68")   # charcoal-brown, lifted more
const ACCENT := Color("9D8DF1")        # soft-periwinkle
const PRIMARY := Color("D52941")       # raspberry
const TEXT := Color("EADEDA")          # dust-grey
const MUTED := Color("BFB8AD")         # silver
const HUMAN_COLOR := Color("AC9EF3")   # soft-periwinkle, lightened
const GOOD := HUMAN_COLOR              # soft-periwinkle, lightened
const PODIUM_1 := PRIMARY              # raspberry
const PODIUM_2 := MUTED                # silver
const PODIUM_3 := ACCENT               # soft-periwinkle


static func box(color: Color, radius: int = 12, margin: int = 12) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(radius)
    style.set_content_margin_all(margin)
    return style


static func panel(color: Color = PANEL) -> PanelContainer:
    var p := PanelContainer.new()
    p.add_theme_stylebox_override("panel", box(color, 14, 18))
    return p


static func label(text: String, size: int = 24, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.horizontal_alignment = align
    return l


static func wrapped(text: String, size: int = 20, color: Color = TEXT) -> Label:
    var l := label(text, size, color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l


static func button(text: String, size: int = 28, primary: bool = false) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, 62)
    b.add_theme_font_size_override("font_size", size)
    var base := PRIMARY if primary else PANEL_LIGHT
    var text_color := Color("1b1b1b") if primary else TEXT
    b.add_theme_stylebox_override("normal", box(base))
    b.add_theme_stylebox_override("hover", box(base.lightened(0.15)))
    b.add_theme_stylebox_override("pressed", box(base.darkened(0.15)))
    b.add_theme_stylebox_override("disabled", box(PANEL.darkened(0.25)))
    var focus := box(Color(0, 0, 0, 0))
    focus.draw_center = false
    focus.set_border_width_all(3)
    focus.border_color = TEXT
    b.add_theme_stylebox_override("focus", focus)
    for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        b.add_theme_color_override(key, text_color)
    b.add_theme_color_override("font_disabled_color", MUTED)
    return b


static func spacer(height: float) -> Control:
    var c := Control.new()
    c.custom_minimum_size = Vector2(0, height)
    return c


static func fmt_time(seconds: float) -> String:
    var s := maxi(ceili(seconds), 0)
    return "%d:%02d" % [floori(s / 60.0), s % 60]


static func ordinal(n: int) -> String:
    var suffix := "th"
    if n % 100 < 11 or n % 100 > 13:
        match n % 10:
            1:
                suffix = "st"
            2:
                suffix = "nd"
            3:
                suffix = "rd"
    return "%d%s" % [n, suffix]


## One table row. `widths` sets each column's minimum width; columns from index 2 are right-aligned.
static func table_row(cells: Array, widths: Array, size: int = 22, color: Color = TEXT, highlight: bool = false) -> Control:
    var wrap := PanelContainer.new()
    var style := box(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.22) if highlight else Color(0, 0, 0, 0), 8, 6)
    wrap.add_theme_stylebox_override("panel", style)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    wrap.add_child(row)
    for i in cells.size():
        var align := HORIZONTAL_ALIGNMENT_RIGHT if i >= 2 else HORIZONTAL_ALIGNMENT_LEFT
        var l := label(str(cells[i]), size, HUMAN_COLOR if highlight and i == 1 else color, align)
        l.custom_minimum_size = Vector2(float(widths[i]), 0)
        l.clip_text = true
        if i == 1:
            l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(l)
    return wrap





static func ignore_mouse(node: Node) -> void:
    if node is Control:
        node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for child in node.get_children():
        ignore_mouse(child)
