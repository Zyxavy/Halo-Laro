extends Node3D
## Test arena for the Player controller and CameraRig. Open PlayerSandbox.tscn and press F6.
## WASD move, SPACE jump, Q/E or right-mouse drag orbit, 1/2/3 switch camera presets.

const PLAYER_SCENE := preload("res://characters/Player.tscn")

var camera: CameraRig
var human: Player
var info: Label


func _ready() -> void:
    _build_world()

    human = PLAYER_SCENE.instantiate()
    human.player_id = 0
    human.input = HumanInput.new()
    human.set_skin_color(Color("ac9ef3"))
    add_child(human)
    human.teleport_to(Vector3(0, 0.5, 8))

    for i in 5:
        var bot: Player = PLAYER_SCENE.instantiate()
        bot.player_id = i + 1
        bot.is_bot = true
        bot.set_skin_color(Color.from_hsv(i / 5.0, 0.55, 0.9))
        var brain := WanderBrain.new()
        brain.bot_player = bot
        var bot_input := BotInput.new()
        bot_input.brain = brain
        bot.input = bot_input
        add_child(bot)
        bot.teleport_to(Vector3(randf_range(-10, 10), 0.5, randf_range(-10, 10)))

    camera = CameraRig.new()
    add_child(camera)
    camera.bind_player(human)

    var layer := CanvasLayer.new()
    add_child(layer)
    info = Label.new()
    info.position = Vector2(16, 12)
    info.add_theme_font_size_override("font_size", 20)
    layer.add_child(info)


func _process(_delta: float) -> void:
    if human == null:
        return
    var speed := Vector2(human.velocity.x, human.velocity.z).length()
    info.text = "WASD move | SPACE jump | Q/E or right-drag orbit | 1 follow  2 high  3 lane\nanim: %s   speed: %.1f" % [human.anim_state, speed]


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1:
                camera.set_preset(CameraRig.Preset.FOLLOW)
            KEY_2:
                camera.set_preset(CameraRig.Preset.HIGH_FOLLOW)
            KEY_3:
                camera.set_preset(CameraRig.Preset.FIXED_LANE)


func _build_world() -> void:
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, 35, 0)
    add_child(sun)

    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    var world_env := WorldEnvironment.new()
    world_env.environment = env
    add_child(world_env)

    _add_box(Vector3(60, 1, 60), Vector3(0, -0.5, 0), Color("6aa84f"))                  # floor
    _add_box(Vector3(3, 1, 3), Vector3(-5, 0.5, 0), Color("b7b7b7"))                    # low box (jump on it)
    _add_box(Vector3(3, 2, 3), Vector3(5, 1.0, -3), Color("999999"))                    # taller box
    _add_box(Vector3(6, 0.3, 3), Vector3(0, 0.6, -8), Color("c27ba0"), Vector3(-0.35, 0, 0))  # ramp
    for x in [-1, 1]:
        _add_box(Vector3(1, 2, 20), Vector3(x * 12, 1, 0), Color("cc4125"))             # side walls


func _add_box(size: Vector3, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    body.rotation = rot
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)
    var mesh := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = size
    mesh.mesh = box_mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    body.add_child(mesh)
    add_child(body)
