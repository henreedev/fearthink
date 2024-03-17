extends TileMap
class_name Level

@export var hue_shift := 0.0;
@export var darken := 0.0;
static var level0_dims := Vector2(200, 240)
var campfire_scale = 0.0
var campfires_visible = false
@onready var game : Game = get_tree().get_first_node_in_group("game")
var level0_campfires = []
var transitioning = false
# Called when the node enters the scene tree for the first time.
func _ready():
	_populate_campfire_lists()

func _populate_campfire_lists():
	for child in $Level0.get_children():
		if child is Campfire:
			level0_campfires.append(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	material.set_shader_parameter("hue_shift", hue_shift)
	var light = 1.0 - darken
	$CanvasModulate.color = Color(light, light, light, 1.0)
	set_campfire_state()

func set_campfire_state():
	if transitioning:
		get_tree().set_group("campfire", "fire_visible", campfires_visible)
		get_tree().set_group("campfire", "fire_scale", Vector2(campfire_scale, campfire_scale))
