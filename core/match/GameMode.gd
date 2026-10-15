class_name GameMode
extends Node
## Base class every mode extends. Frozen contract: do not change without the team lead.
## A mode runs one round, then emits `finished` with a ModeResult.

signal finished(result: ModeResult)

var players: Array[Player] = []
var config: Dictionary = {}
var map_scene: PackedScene


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
