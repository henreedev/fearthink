extends Area2D
class_name Rumor

var speed = 60.0
var dist = 200.0
var final_size = Vector2(3.0, 3.0)
var angle = 0.0 # overwrite this
var final_pos # instantiate this
@onready var timer : Timer = $Timer
var lifetime = 2.0
var creator : NPC 
# Called when the node enters the scene tree for the first time.
func _ready():
	angle = global_position.angle_to_point(get_global_mouse_position())
	final_pos = global_position + Vector2(dist, 0).rotated(angle)
	rotation = angle + PI / 2
	create_tween().tween_property(self, "global_position", final_pos, lifetime).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(self, "scale", final_size, lifetime).set_trans(Tween.TRANS_QUAD)
	create_tween().tween_property(self, "modulate", Color(0.5, 0.5, 0.5, 0.1), lifetime - 1.5).set_trans(Tween.TRANS_EXPO).from(Color(1.2, 1.2, 1.2, 1.0)).set_ease(Tween.EASE_OUT).set_delay(1.5)
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#global_position = global_position.move_toward(final_pos, speed * delta)
	#var time_ratio = 1 - timer.time_left / timer.wait_time
	#scale = lerp(Vector2(1.0, 1.0), Vector2(final_size, final_size), time_ratio)
	pass



func _on_timer_timeout():
	#queue_free()
	pass
	




func _on_area_entered(area):
	if area is NPC and area != creator:
		if area.close_fire:
			area.update_paranoia(0.25)
		else: 
			area.update_paranoia(0.5)
