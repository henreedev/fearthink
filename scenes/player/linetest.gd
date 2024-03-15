extends Line2D

@onready var parent : Marker2D = get_parent()
@export var length = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	top_level = true
	clear_points()


func _physics_process(delta):
	add_point(parent.global_position)
	
	if points.size() > length:
		remove_point(0)
