class_name RoundResultsScreen
extends UiScreen
## Points earned this round, ranked, with running totals. Shown for ~4 seconds.

var _mode_name: String = ""
var _awarded: Dictionary = {}
var _totals: Dictionary = {}
var _names: Dictionary = {}


func setup(mode_name: String, awarded: Dictionary, totals: Dictionary, names: Dictionary) -> void:
    _mode_name = mode_name
    _awarded = awarded
    _totals = totals
    _names = names


func _ready() -> void:
    add_bg(Color(0.07, 0.12, 0.24, 0.95))
    var col := centered_column(780.0, 6)
    col.add_child(UIKit.label("%s - RESULTS" % _mode_name.to_upper(), 42, UIKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(UIKit.spacer(8))
    var widths := [50, 300, 150, 120]
    col.add_child(UIKit.table_row(["#", "PLAYER", "THIS ROUND", "TOTAL"], widths, 18, UIKit.MUTED))

    var rows: Array = []
    for id in _awarded:
        rows.append({"id": int(id), "pts": int(_awarded[id])})
    rows.sort_custom(_sort_rows)
    for i in rows.size():
        var id: int = rows[i]["id"]
        col.add_child(UIKit.table_row(
            [i + 1, _names.get(id, "Player %d" % id), "+%d" % rows[i]["pts"], int(_totals.get(id, 0))],
            widths, 22, UIKit.TEXT, id == UIKit.HUMAN_ID))


func _sort_rows(a: Dictionary, b: Dictionary) -> bool:
    if a["pts"] != b["pts"]:
        return a["pts"] > b["pts"]
    return a["id"] < b["id"]
