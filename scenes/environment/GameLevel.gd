extends Node2D
class_name GameLevel

@onready var campfires = get_tree().get_nodes_in_group("campfire")

# Called when the node enters the scene tree for the first time.
func _ready():
	for campfire : Campfire in campfires:
		var wood : Sprite2D = campfire.get_child(0)
		create_tween().tween_property(wood, "offset", Vector2(0, 0), 1.5).from(Vector2(0, -100)).set_trans(Tween.TRANS_BOUNCE)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
