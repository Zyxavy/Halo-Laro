class_name PodiumScreen
extends UiScreen
## Final results: podium for the top 3, full standings, your best matches, Back to Menu.

signal back_pressed

var _manager: MatchManager
var _standings: Array = []
var _names: Dictionary = {}
var _human_rank: int = 0
var _board_rank: int = -1
var _board: Array = []
var _countdown: Label


func setup(manager: MatchManager, standings: Array, names: Dictionary, human_rank: int, board_rank: int, board: Array) -> void:
    _manager = manager
    _standings = standings
    _names = names
    _human_rank = human_rank
    _board_rank = board_rank
    _board = board


func _ready() -> void:
    add_bg(UIKit.BG)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 24)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    margin.add_child(root)

    root.add_child(UIKit.label("FINAL RESULTS", 40, UIKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
    var verdict := "You finished %s of %d" % [UIKit.ordinal(_human_rank), _standings.size()]
    if _human_rank == 1:
        verdict = "YOU WIN!"
    root.add_child(UIKit.label(verdict, 26, UIKit.HUMAN_COLOR, HORIZONTAL_ALIGNMENT_CENTER))

    # Podium: 2nd, 1st, 3rd
    var podium := HBoxContainer.new()
    podium.alignment = BoxContainer.ALIGNMENT_CENTER
    podium.add_theme_constant_override("separation", 20)
    podium.custom_minimum_size = Vector2(0, 230)
    root.add_child(podium)
    var heights := {0: 120.0, 1: 90.0, 2: 66.0}
    var colors := {0: UIKit.PODIUM_1, 1: UIKit.PODIUM_2, 2: UIKit.PODIUM_3}
    for slot in [1, 0, 2]:
        if slot >= _standings.size():
            continue
        podium.add_child(_podium_column(slot, heights[slot], colors[slot]))

    # Bottom: standings and best matches
    var bottom := HBoxContainer.new()
    bottom.add_theme_constant_override("separation", 20)
    bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(bottom)
    bottom.add_child(_standings_panel())
    bottom.add_child(_board_panel())

    var footer := HBoxContainer.new()
    footer.add_theme_constant_override("separation", 20)
    root.add_child(footer)
    _countdown = UIKit.label("", 20, UIKit.MUTED)
    _countdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    footer.add_child(_countdown)
    var back := UIKit.button("BACK TO MENU", 26, true)
    back.custom_minimum_size = Vector2(320, 62)
    back.pressed.connect(func(): back_pressed.emit())
    footer.add_child(back)
    back.grab_focus()


func _podium_column(slot: int, block_height: float, color: Color) -> Control:
    var id: int = _standings[slot]["player_id"]
    var col := VBoxContainer.new()
    col.size_flags_vertical = Control.SIZE_SHRINK_END
    col.custom_minimum_size = Vector2(230, 0)
    var is_human := id == UIKit.HUMAN_ID
    col.add_child(UIKit.label(String(_names.get(id, "Player %d" % id)), 26, UIKit.HUMAN_COLOR if is_human else UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(UIKit.label("%d pts" % int(_standings[slot]["total"]), 22, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    var block := ColorRect.new()
    block.color = color
    block.custom_minimum_size = Vector2(0, block_height)
    col.add_child(block)
    var numeral := UIKit.label(str(slot + 1), 52, Color("1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER)
    numeral.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    numeral.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    block.add_child(numeral)
    return col


func _standings_panel() -> Control:
    var panel := UIKit.panel(UIKit.PANEL)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    panel.add_child(box)
    box.add_child(UIKit.label("FULL STANDINGS", 20, UIKit.ACCENT))
    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation", 24)
    box.add_child(columns)
    var half := ceili(_standings.size() / 2.0)
    var widths := [40, 150, 56]
    for c in 2:
        var list := VBoxContainer.new()
        list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        list.add_theme_constant_override("separation", 0)
        columns.add_child(list)
        for i in range(c * half, mini((c + 1) * half, _standings.size())):
            var id: int = _standings[i]["player_id"]
            list.add_child(UIKit.table_row([i + 1, _names.get(id, "Player %d" % id), int(_standings[i]["total"])],
                widths, 19, UIKit.TEXT, id == UIKit.HUMAN_ID))
    return panel


func _board_panel() -> Control:
    var panel := UIKit.panel(UIKit.PANEL)
    panel.custom_minimum_size = Vector2(380, 0)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    panel.add_child(box)
    box.add_child(UIKit.label("YOUR BEST MATCHES", 20, UIKit.ACCENT))
    if _board_rank == 1:
        box.add_child(UIKit.label("New personal best!", 18, UIKit.GOOD))
    elif _board_rank > 1:
        box.add_child(UIKit.label("This match ranks #%d" % _board_rank, 18, UIKit.MUTED))
    var widths := [44, 190, 70]
    for i in mini(_board.size(), 5):
        var e: Dictionary = _board[i]
        box.add_child(UIKit.table_row([i + 1, e["name"], int(e["total"])], widths, 18, UIKit.TEXT, i + 1 == _board_rank))
    return panel


func _process(_delta: float) -> void:
    if _manager != null:
        _countdown.text = "Returning to menu in %d s" % maxi(ceili(_manager.phase_time_left), 0)
