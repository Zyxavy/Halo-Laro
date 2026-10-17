class_name GameMode
extends Node
## Base class every mode extends. Frozen contract: do not change without the team lead.
## A mode runs one round, then emits `finished` with a ModeResult.
##
## Added helpers (additive, the contract itself is unchanged):
##   camera          the shared CameraRig, set by MatchManager before setup()
##   human()         the human player, or null
##   place_player()  put a player into the world at a position

signal finished(result: ModeResult)

var players: Array[Player] = []
var config: Dictionary = {}
var map_scene: PackedScene
var camera: CameraRig


func setup(p_players: Array[Player], p_map: PackedScene, p_config: Dictionary) -> void:
    players = p_players
    map_scene = p_map
    config = p_config


func start() -> void:
    pass


func tick(_delta: float) -> void:
    pass


func get_hud_data() -> Dictionary:
    return {}


func force_end() -> void:
    pass


func teardown() -> void:
    queue_free()


func human() -> Player:
    for p in players:
        if not p.is_bot:
            return p
    return null


## Adds `p` under `parent` (removing it from any old parent) and moves it to `pos`.
func place_player(p: Player, parent: Node, pos: Vector3, yaw_deg: float = 0.0) -> void:
    if p.get_parent() != parent:
        if p.get_parent() != null:
            p.get_parent().remove_child(p)
        parent.add_child(p)
    p.teleport_to(pos, deg_to_rad(yaw_deg))
