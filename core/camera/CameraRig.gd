class_name CameraRig
extends Node3D
## One shared third-person camera. Modes ask for a preset; they never build their own camera.
##
##   FOLLOW       behind the player, close. Q / E or right-mouse drag orbits.   (Tumbang Preso)
##   HIGH_FOLLOW  high, angled down so the whole field reads. Fixed direction.  (Agawan Base)
##   FIXED_LANE   side/behind view along a lane. Fixed direction.               (Luksong Baka)
##
## For the human player the rig also sets `player.move_yaw`, so WASD is camera-relative.

enum Preset { FOLLOW, HIGH_FOLLOW, FIXED_LANE }

const PRESETS := {
    Preset.FOLLOW: {"distance": 6.5, "pitch": -22.0, "height": 1.6, "follow_speed": 10.0, "fov": 70.0, "orbit": true},
    Preset.HIGH_FOLLOW: {"distance": 17.0, "pitch": -58.0, "height": 0.5, "follow_speed": 6.0, "fov": 60.0, "orbit": false},
    Preset.FIXED_LANE: {"distance": 9.0, "pitch": -14.0, "height": 1.8, "follow_speed": 8.0, "fov": 65.0, "orbit": false},
}

@export var orbit_speed: float = 2.4
@export var mouse_sensitivity: float = 0.005
@export var blend_speed: float = 5.0

var camera: Camera3D
var yaw: float = 0.0  # radians. Forward for the bound player is -Z rotated by this.
var preset: Preset = Preset.FOLLOW

var _pivot: Node3D
var _target: Node3D
var _bound_player: Player
var _anchor: Vector3 = Vector3.ZERO
var _goal_yaw: float = 0.0
var _goal: Dictionary = {}
var _distance: float = 6.5
var _pitch: float = -22.0
var _height: float = 1.6
var _fov: float = 70.0
var _follow_speed: float = 10.0
var _orbit: bool = true


func _ready() -> void:
    _pivot = Node3D.new()
    add_child(_pivot)
    camera = Camera3D.new()
    _pivot.add_child(camera)
    camera.current = true
    set_preset(preset, rad_to_deg(yaw), true)


## Choose a preset. `yaw_deg` is the facing direction of the camera (0 = looking toward -Z).
## `snap` jumps there instantly instead of blending.
func set_preset(new_preset: Preset, yaw_deg: float = 0.0, snap: bool = false) -> void:
    preset = new_preset
    _goal = PRESETS[new_preset].duplicate()
    _orbit = _goal["orbit"]
    _goal_yaw = deg_to_rad(yaw_deg)
    if snap:
        yaw = _goal_yaw
        _distance = _goal["distance"]
        _pitch = _goal["pitch"]
        _height = _goal["height"]
        _follow_speed = _goal["follow_speed"]
        _fov = _goal["fov"]
        _apply()


func follow(node: Node3D, snap: bool = true) -> void:
    _target = node
    if snap and node != null and node.is_inside_tree():
        _anchor = node.global_position
        _apply()


## Follow a player AND make their input camera-relative.
func bind_player(player: Player, snap: bool = true) -> void:
    _bound_player = player
    follow(player, snap)


func clear() -> void:
    _target = null
    _bound_player = null


func _process(delta: float) -> void:
    if _goal.is_empty() or camera == null:
        return

    var k := 1.0 - exp(-blend_speed * delta)
    _distance = lerpf(_distance, _goal["distance"], k)
    _pitch = lerpf(_pitch, _goal["pitch"], k)
    _height = lerpf(_height, _goal["height"], k)
    _fov = lerpf(_fov, _goal["fov"], k)
    _follow_speed = lerpf(_follow_speed, _goal["follow_speed"], k)

    if _orbit:
        var turn := 0.0
        if Input.is_physical_key_pressed(KEY_Q):
            turn += 1.0
        if Input.is_physical_key_pressed(KEY_E):
            turn -= 1.0
        yaw += turn * orbit_speed * delta
    else:
        yaw = lerp_angle(yaw, _goal_yaw, k)

    if is_instance_valid(_target) and _target.is_inside_tree():
        _anchor = _anchor.lerp(_target.global_position, 1.0 - exp(-_follow_speed * delta))

    if is_instance_valid(_bound_player):
        _bound_player.move_yaw = yaw

    _apply()


func _unhandled_input(event: InputEvent) -> void:
    if _orbit and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        yaw -= event.relative.x * mouse_sensitivity
        _goal["pitch"] = clampf(_goal["pitch"] - event.relative.y * mouse_sensitivity * 20.0, -45.0, -8.0)


func _apply() -> void:
    if camera == null:
        return
    global_position = _anchor + Vector3.UP * _height
    rotation.y = yaw
    _pivot.rotation.x = deg_to_rad(_pitch)
    camera.position = Vector3(0.0, 0.0, _distance)
    camera.fov = _fov
