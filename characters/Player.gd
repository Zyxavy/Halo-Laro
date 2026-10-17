class_name Player
extends CharacterBody3D
## One shared character for humans and bots. Reads an InputProvider, moves with a little
## inertia (party-game feel), faces where it runs, and can jump with coyote time + jump buffer.
##
## `move_yaw` says which way "forward" is for this player's input:
##   - human: the CameraRig sets it every frame, so movement is camera-relative
##   - bots:  stays 0, so their move vector is a plain world-space direction (x = +X, y = +Z)
## Modes that need special movement (auto-run, frozen, no jump) use the flags below instead of
## replacing this script.

signal jumped
signal landed
signal anim_changed(anim_state: String)

@export var max_speed: float = 7.0
@export var ground_accel: float = 40.0
@export var ground_decel: float = 50.0
@export var air_accel: float = 14.0
@export var jump_velocity: float = 9.0
@export var gravity: float = 26.0
@export var turn_speed: float = 14.0
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12

var player_id: int = -1
var display_name: String = ""
var team_id: int = -1
var is_bot: bool = false
var alive: bool = true
var input: InputProvider

var move_yaw: float = 0.0
var frozen: bool = false          # true: no input, stands still (tag pause, countdowns)
var move_enabled: bool = true     # false: ignores the move vector (mode drives movement itself)
var jump_enabled: bool = true
var speed_scale: float = 1.0      # modes can slow or boost players
var anim_state: String = "idle"   # idle | run | jump | fall

var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _was_on_floor: bool = false


func _physics_process(delta: float) -> void:
    if input == null:
        return

    var wish := Vector3.ZERO
    var jump_pressed := false
    if alive and not frozen:
        input.poll(delta)
        if move_enabled:
            wish = Vector3(input.move.x, 0.0, input.move.y).rotated(Vector3.UP, move_yaw)
            if wish.length() > 1.0:
                wish = wish.normalized()
        jump_pressed = input.action_a_pressed

    # Horizontal movement with acceleration.
    var horizontal := Vector3(velocity.x, 0.0, velocity.z)
    var accel := air_accel
    if is_on_floor():
        accel = ground_accel if wish.length() > 0.01 else ground_decel
    horizontal = horizontal.move_toward(wish * max_speed * speed_scale, accel * delta)
    velocity.x = horizontal.x
    velocity.z = horizontal.z

    # Gravity, coyote time, jump buffering.
    if is_on_floor():
        _coyote_left = coyote_time
        if velocity.y < 0.0:
            velocity.y = 0.0
    else:
        _coyote_left = maxf(_coyote_left - delta, 0.0)
        velocity.y -= gravity * delta

    if jump_pressed:
        _jump_buffer_left = jump_buffer_time
    else:
        _jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)

    if jump_enabled and _jump_buffer_left > 0.0 and _coyote_left > 0.0:
        velocity.y = jump_velocity
        _jump_buffer_left = 0.0
        _coyote_left = 0.0
        jumped.emit()

    move_and_slide()

    if is_on_floor() and not _was_on_floor:
        landed.emit()
    _was_on_floor = is_on_floor()

    _face_movement(delta, horizontal)
    _update_anim_state(horizontal)


## Puts the player at a position (the player must already be in the scene tree).
func teleport_to(pos: Vector3, yaw: float = 0.0) -> void:
    global_position = pos
    velocity = Vector3.ZERO
    face_yaw(yaw)
    _was_on_floor = false


func face_yaw(yaw: float) -> void:
    var visual := get_node_or_null("Visual") as Node3D
    if visual != null:
        visual.rotation.y = yaw


func facing_yaw() -> float:
    var visual := get_node_or_null("Visual") as Node3D
    return visual.rotation.y if visual != null else 0.0


func set_skin_color(color: Color) -> void:
    var body := get_node_or_null("Visual/Body") as MeshInstance3D
    if body != null:
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        body.material_override = mat


func _face_movement(delta: float, horizontal: Vector3) -> void:
    if horizontal.length() < 0.5:
        return
    var visual := get_node_or_null("Visual") as Node3D
    if visual == null:
        return
    # The model's forward is -Z, so the yaw that points it along `horizontal` is:
    var target_yaw := atan2(-horizontal.x, -horizontal.z)
    visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))


func _update_anim_state(horizontal: Vector3) -> void:
    var new_state := "idle"
    if not is_on_floor():
        new_state = "jump" if velocity.y > 0.0 else "fall"
    elif horizontal.length() > 0.5:
        new_state = "run"
    if new_state == anim_state:
        return
    anim_state = new_state
    anim_changed.emit(new_state)
    # Art hook: if the character model has an AnimationPlayer with clips named like the states, play them.
    var anim_player := get_node_or_null("AnimationPlayer") as AnimationPlayer
    if anim_player != null and anim_player.has_animation(new_state):
        anim_player.play(new_state)
