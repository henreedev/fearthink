extends TileMap
class_name Level

@export var hue_shift := 0.0;
@export var darken := 0.0;
static var level0_dims := Vector2(200, 240)
var campfire_scale = 0.0
var campfires_visible = false
@onready var game : Game = get_tree().get_first_node_in_group("game")
var level_campfires = []
var transitioning = false
@onready var hud : HUD = get_tree().get_first_node_in_group("hud")

@export var level0 : PackedScene
@export var level1 : PackedScene
@export var level2 : PackedScene
@export var level3 : PackedScene


# Called when the node enters the scene tree for the first time.
func _ready():
	load_new_level(0)
	_populate_campfire_lists()

func _populate_campfire_lists():
	for child in $CurrentLevel.get_children():
		if child is Campfire:
			level_campfires.append(child)

func load_new_level(index):
	match index:
		0:
			add_child(level0.instantiate())
			hud.npcs = get_tree().get_nodes_in_group("npc")
		1:
			$CurrentLevel.queue_free()
			remove_child($CurrentLevel)
			add_child(level1.instantiate())
			hud.npcs = get_tree().get_nodes_in_group("npc")
		2:
			$CurrentLevel.queue_free()
			remove_child($CurrentLevel)
			add_child(level2.instantiate())
			hud.npcs = get_tree().get_nodes_in_group("npc")
		3:
			$CurrentLevel.queue_free()
			remove_child($CurrentLevel)
			add_child(level3.instantiate())
			hud.npcs = get_tree().get_nodes_in_group("npc")

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
