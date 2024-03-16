extends TileMap
class_name Level

@export var hue_shift := 0.0;
@export var darken := 0.0;
static var level0_dims := Vector2(160, 160)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	material.set_shader_parameter("hue_shift", hue_shift)
	var light = 1.0 - darken
	$CanvasModulate.color = Color(light, light, light, 1.0)
