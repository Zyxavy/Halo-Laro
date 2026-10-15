class_name ScoreManager
extends RefCounted
## Turns ModeResults into points and keeps standings. All numbers come from config.json.

var totals: Dictionary = {}
var round_history: Array[Dictionary] = []


func reset(player_ids: Array[int]) -> void:
    totals.clear()
    round_history.clear()
    for id in player_ids:
        totals[id] = 0


func apply(mode_id: String, result: ModeResult) -> Dictionary:
    var awarded: Dictionary = {}
    match result.kind:
        "placement":
            var table: Array = Config.get_value("placement_points", [1])
            for i in result.placements.size():
                var slot := mini(i, table.size() - 1)
                awarded[result.placements[i]] = int(table[slot])
        "points":
            for id in result.points:
                awarded[id] = int(result.points[id])
        "team":
            var win_pts := int(Config.get_value("team_win_points", 6))
            var mvp_pts := int(Config.get_value("team_mvp_points", 8))
            var loss_pts := int(Config.get_value("team_loss_points", 2))
            for id in result.team_of:
                if result.team_of[id] == result.winning_team:
                    awarded[id] = mvp_pts if id == result.mvp else win_pts
                else:
                    awarded[id] = loss_pts
    for id in awarded:
        totals[id] = int(totals.get(id, 0)) + int(awarded[id])
        Events.score_changed.emit(id, totals[id])
    round_history.append({"mode_id": mode_id, "awarded": awarded})
    return awarded


func best_round(player_id: int) -> int:
    var best := 0
    for entry in round_history:
        best = maxi(best, int(entry["awarded"].get(player_id, 0)))
    return best


## Highest total first. Tiebreak: best single round. (Final ties: random via MatchManager RNG.)
func standings() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for id in totals:
        rows.append({"player_id": id, "total": totals[id], "best": best_round(id)})
    rows.sort_custom(func(a, b):
        if a["total"] != b["total"]:
            return a["total"] > b["total"]
        return a["best"] > b["best"]
    )
    return rows
