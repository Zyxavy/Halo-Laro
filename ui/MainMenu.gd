class_name MainMenu
extends UiScreen
## Title screen: name, Quick Match, Browse Server (coming soon), How to Play, Quit, best scores.

signal quick_match_pressed
signal quit_pressed

var _modes_info: Dictionary = {}
var _how_to_play: Control


func setup(modes_info: Dictionary) -> void:
    _modes_info = modes_info


func _ready() -> void:
    add_bg(UIKit.BG)
    var col := centered_column(440.0, 12)

    col.add_child(UIKit.label(Game.game_title.to_upper(), 68, UIKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(UIKit.label("Three random Filipino games. One winner.", 22, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(UIKit.spacer(14))

    var name_edit := LineEdit.new()
    name_edit.placeholder_text = "Your name"
    name_edit.text = Game.player_name
    name_edit.max_length = 16
    name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_edit.custom_minimum_size = Vector2(0, 48)
    name_edit.add_theme_font_size_override("font_size", 24)
    name_edit.text_changed.connect(_on_name_changed)
    col.add_child(name_edit)

    var quick := UIKit.button("QUICK MATCH", 32, true)
    quick.pressed.connect(func(): quick_match_pressed.emit())
    col.add_child(quick)

    var browse := UIKit.button("BROWSE SERVER  -  COMING SOON", 22)
    browse.disabled = true
    col.add_child(browse)

    var how := UIKit.button("HOW TO PLAY", 24)
    how.pressed.connect(_toggle_how_to_play)
    col.add_child(how)

    if not OS.has_feature("web"):
        var quit := UIKit.button("QUIT", 24)
        quit.pressed.connect(func(): quit_pressed.emit())
        col.add_child(quit)

    col.add_child(UIKit.spacer(6))
    col.add_child(_best_scores())
    _build_how_to_play()
    quick.grab_focus()


func _on_name_changed(text: String) -> void:
    var cleaned := text.strip_edges()
    Game.player_name = cleaned if cleaned != "" else "Player"


func _best_scores() -> Control:
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    box.add_child(UIKit.label("BEST MATCHES", 16, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    var entries := LeaderboardStore.load_entries()
    if entries.is_empty():
        box.add_child(UIKit.label("Play a match to set your first score!", 18, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    for i in mini(entries.size(), 3):
        var e: Dictionary = entries[i]
        box.add_child(UIKit.label("%d.  %s  -  %d pts" % [i + 1, e["name"], int(e["total"])], 20, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
    return box


func _toggle_how_to_play() -> void:
    _how_to_play.visible = not _how_to_play.visible


func _build_how_to_play() -> void:
    _how_to_play = Control.new()
    _how_to_play.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _how_to_play.visible = false
    add_child(_how_to_play)

    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.75)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _how_to_play.add_child(dim)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _how_to_play.add_child(center)

    var panel := UIKit.panel(UIKit.PANEL)
    center.add_child(panel)
    var box := VBoxContainer.new()
    box.custom_minimum_size = Vector2(780, 0)
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)

    box.add_child(UIKit.label("HOW TO PLAY", 36, UIKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
    box.add_child(UIKit.wrapped("Each match is 3 random games. Points from every game add up. Most points wins.", 20, UIKit.MUTED))
    for id in _modes_info:
        var info: Dictionary = _modes_info[id]
        box.add_child(UIKit.spacer(6))
        box.add_child(UIKit.label(String(info.get("name", id)), 26, UIKit.ACCENT))
        for rule in info.get("rules", []):
            box.add_child(UIKit.wrapped("- " + String(rule), 18, UIKit.TEXT))
    box.add_child(UIKit.spacer(10))
    var close := UIKit.button("CLOSE", 24, true)
    close.pressed.connect(_toggle_how_to_play)
    box.add_child(close)
