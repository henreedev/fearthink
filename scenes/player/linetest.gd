extends Line2D

@onready var parent : Marker2D = get_parent()
const LENGTH = 150
var length = LENGTH # to be scaled by fps
var tween : Tween
# Called when the node enters the scene tree for the first time.
func _ready():
	top_level = true
	clear_points()

func _process(delta):
	if visible:
		var fps = Performance.get_monitor(Performance.TIME_FPS)
		length = LENGTH * (fps / 144.0)
		add_point(parent.global_position)
		
		while points.size() > length:
			remove_point(0)
		if points.size() == length:
			if points[length / 2].distance_squared_to(points[length - 1]) == 0.0:
				if tween:
					tween.kill()
				tween = create_tween()
				tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.1)
			else:
				if tween:
					tween.kill()
				tween = create_tween()
				tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
