extends Area2D
class_name Scream

var initial_scale = 0.2
var time_to_normal_size = 0.25
var creator : NPC

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play()
	create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), time_to_normal_size).from(Vector2(initial_scale, initial_scale)).set_trans(Tween.TRANS_EXPO)
	create_tween().tween_property($AnimatedSprite2D, "speed_scale", 1.0, time_to_normal_size).from(0.0).set_trans(Tween.TRANS_EXPO)

func _on_animated_sprite_2d_animation_finished():
	queue_free()

func _on_area_entered(area):
	if area is NPC and area != creator:
		area.update_paranoia(0.33)
		area.begin_cowering()
