## Automated check of the Player controller and CameraRig. Run headless:
##   godot --headless --fixed-fps 60 --path . res://tools/tests/ControllerTest.tscn
## Prints PASS/FAIL per check and exits with code 1 if any fail.
extends Node3D

class ScriptedInput extends InputProvider:
    func poll(_d: float) -> void:
        pass

var fails := 0
var landed_count := 0
var jumped_count := 0
var anim_log: Array[String] = []


func check(test_name: String, ok: bool, detail: Variant = "") -> void:
    print(("PASS  " if ok else "FAIL  "), test_name, "  ", detail)
    if not ok:
        fails += 1


func frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame


func _ready() -> void:
    var sandbox: Node3D = load("res://tools/PlayerSandbox.tscn").instantiate()
    add_child(sandbox)
    await frames(2)
    var p: Player = sandbox.human
    var rig: CameraRig = sandbox.camera
    var si := ScriptedInput.new()
    p.input = si
    p.landed.connect(func(): landed_count += 1)
    p.jumped.connect(func(): jumped_count += 1)
    p.anim_changed.connect(func(s): anim_log.append(s))

    var bot_start: Array[Vector3] = []
    for c in sandbox.get_children():
        if c is Player and c.is_bot:
            bot_start.append(c.global_position)

    # 1. settle on the floor
    p.teleport_to(Vector3(0, 0.2, 8))
    await frames(40)
    check("stands on floor", p.is_on_floor(), p.global_position)

    # 2. forward with yaw 0 goes toward -Z
    rig.set_preset(CameraRig.Preset.FOLLOW, 0.0, true)
    await frames(5)
    var z0 := p.global_position.z
    var x0 := p.global_position.x
    si.move = Vector2(0, -1)
    await frames(60)
    si.move = Vector2.ZERO
    check("forward moves -Z", z0 - p.global_position.z > 4.0, "dz=%.2f" % (z0 - p.global_position.z))
    check("forward does not drift in X", absf(p.global_position.x - x0) < 0.5)
    await frames(30)
    var stop_speed := Vector2(p.velocity.x, p.velocity.z).length()
    check("decelerates to a stop", stop_speed < 0.1, stop_speed)

    # 3. camera-relative: yaw 90 deg means forward is -X
    p.teleport_to(Vector3(0, 0.2, 8))
    rig.set_preset(CameraRig.Preset.FIXED_LANE, 90.0, true)
    await frames(40)
    var xa := p.global_position.x
    si.move = Vector2(0, -1)
    await frames(60)
    si.move = Vector2.ZERO
    check("camera-relative: forward at yaw 90 goes -X", xa - p.global_position.x > 4.0, "dx=%.2f" % (xa - p.global_position.x))
    check("camera sits behind player (+X of player)", rig.camera.global_position.x > p.global_position.x + 3.0,
        "cam.x=%.1f player.x=%.1f" % [rig.camera.global_position.x, p.global_position.x])
    check("player model turned toward -X", absf(wrapf(p.facing_yaw() - PI / 2.0, -PI, PI)) < 0.35, p.facing_yaw())
    await frames(30)

    # 4. jump
    var top := p.global_position.y
    si.action_a_pressed = true
    await frames(1)
    si.action_a_pressed = false
    for i in 60:
        await frames(1)
        top = maxf(top, p.global_position.y)
    check("jump reaches ~1.5 m", top > 1.2 and top < 2.2, "peak y=%.2f" % top)
    check("lands again", p.is_on_floor() and landed_count >= 1, "landed=%d" % landed_count)
    check("anim states seen", "run" in anim_log and "jump" in anim_log and "fall" in anim_log, anim_log)

    # 5a. jump buffer: press ~0.06 s before landing -> jumps right on landing
    p.teleport_to(Vector3(0, 0.9, 8))
    var jumps_before := jumped_count
    await frames(12)
    si.action_a_pressed = true
    await frames(1)
    si.action_a_pressed = false
    await frames(20)
    check("jump buffer: early press still jumps on landing", jumped_count == jumps_before + 1, "jumps +%d" % (jumped_count - jumps_before))
    await frames(60)

    # 5b. coyote time: press jump 3 frames after walking off an edge
    rig.set_preset(CameraRig.Preset.FOLLOW, 0.0, true)
    p.teleport_to(Vector3(-5, 1.2, 0.8))
    await frames(30)
    si.move = Vector2(0, 1)
    var guard := 0
    while p.is_on_floor() and guard < 120:
        await frames(1)
        guard += 1
    await frames(3)
    jumps_before = jumped_count
    si.action_a_pressed = true
    await frames(1)
    si.action_a_pressed = false
    si.move = Vector2.ZERO
    await frames(5)
    check("coyote time: jump works just after leaving a ledge", jumped_count == jumps_before + 1 and guard < 120, "guard=%d" % guard)
    await frames(60)

    # 6. frozen
    p.teleport_to(Vector3(0, 0.2, 8))
    await frames(30)
    p.frozen = true
    si.move = Vector2(0, -1)
    var fp := p.global_position
    await frames(40)
    check("frozen player does not move", p.global_position.distance_to(fp) < 0.05)
    p.frozen = false
    si.move = Vector2.ZERO

    # 7. bots moved using the same controller
    var moved := 0
    var idx := 0
    for c in sandbox.get_children():
        if c is Player and c.is_bot:
            if c.global_position.distance_to(bot_start[idx]) > 1.0:
                moved += 1
            idx += 1
    check("bots wander with the same controller", moved >= 3, "%d/%d moved" % [moved, idx])

    # 8. FOLLOW camera distance sane
    rig.set_preset(CameraRig.Preset.FOLLOW, 0.0, true)
    p.teleport_to(Vector3(0, 0.2, 8))
    await frames(60)
    var d := rig.camera.global_position.distance_to(p.global_position)
    check("follow camera distance 5-9 m", d > 5.0 and d < 9.0, "%.2f" % d)
    check("camera is current", rig.camera.current)

    print("RESULT fails=", fails)
    get_tree().quit(1 if fails > 0 else 0)
