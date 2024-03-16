extends Area2D

class_name NPC

enum State {IDLE, WALKING, FLEEING, COWERING, FREEZE}

var state : State = State.WALKING

@export var speed := 50.0
@export var wander_tendency := 0.1 # 0.0 to 1.0, likelyhood to leave campfire and walk in a random direction 
var paranoia := 0.0
var max_paranoia := 100.0
var can_cower = true
var cower_duration = 1.5
var cower_cooldown = 5.0

# Campfire following variables
var following_campfire : Campfire
var target_point : Vector2 = Vector2(0, 0)
var point_index : int

@onready var sprite : AnimatedSprite2D = $AS 

# Called when the node enters the scene tree for the first time.
func _ready():
	follow_random_campfire()
	begin_walking()

func follow_random_campfire():
	# remove self from current campfire
	if following_campfire:
		following_campfire.clear_npc(self)
	# find and follow a new one (can be same)
	var campfires : Array = get_tree().get_nodes_in_group("campfire")
	var rand = randi_range(0, campfires.size() - 1)
	var campfire : Campfire = campfires[rand]
	campfire.follow_random_point(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_act_on_state(delta)
	_set_shader_params()

func _set_shader_params():
	sprite.material.set_shader_parameter("fear_progress", paranoia)

func _act_on_state(delta):
	match state:
		State.IDLE:
			pass
		State.WALKING:
			position = position.move_toward(target_point, speed * delta)
		State.FLEEING:
			pass
		State.COWERING:
			pass
		State.FREEZE:
			pass

func begin_idle():
	sprite.animation = "idle"
	sprite.play()

func begin_walking():
	sprite.animation = "walk"
	sprite.play()
	sprite.material.set_shader_parameter("flashing", false)

func begin_fleeing():
	sprite.animation = "flee"
	sprite.play()

func begin_cowering():
	sprite.animation = "cower"
	sprite.play()
	sprite.material.set_shader_parameter("flashing", true)

func begin_freeze():
	sprite.pause()

