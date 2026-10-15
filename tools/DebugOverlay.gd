extends CanvasLayer
## Add this scene to a level while developing: FPS and the match seed.

var _label := Label.new()


func _ready() -> void:
    layer = 100
    add_child(_label)


func _process(_delta: float) -> void:
    _label.text = "FPS %d | seed %d" % [Engine.get_frames_per_second(), Game.match_seed]
