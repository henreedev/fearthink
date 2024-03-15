extends Area2D

class_name NPC

enum State{IDLE, WALKING, FLEEING, COWERING}

@export var speed := 10.0
var paranoia := 0.0
var max_paranoia := 100.0
var can_cower = true
var cower_duration = 1.5
var cower_cooldown = 5.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
