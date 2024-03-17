extends Area2D

class_name NPC

enum State {IDLE, WALKING, FLEEING, COWERING, FREEZE}

var state : State = State.WALKING

@export var speed := 30.0
@export var wander_tendency := 0.02 # 0.0 to 1.0, likelyhood to leave campfire and walk in a random direction 
var paranoia := 0.0
var max_paranoia := 100.0
var can_cower = true
var cower_duration = 1.5
var cower_cooldown = 5.0
var last_pos : Vector2 = Vector2(0, 0)
var wander_range := 180.0
var inhabited = false
@onready var timer : Timer = $WanderTimer
@onready var player : Player = get_tree().get_first_node_in_group("player")
var wandering = false
# Campfire following variables
var following_campfire : Campfire
var target_point : Vector2 = Vector2(0, 0)
var point_index : int
var close_fire = false
@onready var sprite : AnimatedSprite2D = $AS 
const FLEE_SPEED_MOD = 1.75

# Called when the node enters the scene tree for the first time.
func _ready():
	follow_random_campfire()
	begin_walking()
	timer.timeout.connect(on_wander_timeout)
	var shader_mat : ShaderMaterial = ShaderMaterial.new()
	shader_mat.shader = load("res://scenes/npcs/npc-outline.gdshader")
	shader_mat.set_shader_parameter("gradient", load("res://scenes/npcs/woman.tscn::GradientTexture1D_qoljp"))
	shader_mat.set_shader_parameter("flash_freq", 0.25)
	shader_mat.set_shader_parameter("base_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	shader_mat.set_shader_parameter("flash_color", Color(0.83, 0.83, 0.83, 1.0))
	sprite.material = shader_mat

func follow_random_campfire():
	# remove self from current campfire
	if following_campfire:
		following_campfire.clear_npc(self)
	# find and follow a new one (can be same)
	var campfires : Array = get_tree().get_nodes_in_group("campfire")
	var found = false
	for campfire : Campfire in campfires:
		if not campfire.slots_full:
			campfire.follow_random_point(self)
			found = true
	if not found:
		campfires[randi_range(0, campfires.size() - 1)].follow_random_point(self)

func wander():
	if following_campfire:
		following_campfire.clear_npc(self)
	target_point = global_position + Vector2(wander_range, 0).rotated(randf() * 2 * PI)
	wandering = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_act_on_state(delta)
	_set_shader_params()

func _set_shader_params():
	sprite.material.set_shader_parameter("fear_progress", paranoia)

func update_paranoia(val):
	if player.state != Player.State.PLANNING:
		paranoia += val
		paranoia = clampf(paranoia, 0, max_paranoia)

func _act_on_state(delta):
	match state:
		State.IDLE:
			const fear_gain = 0.05
			if not close_fire:
				update_paranoia(fear_gain * delta)
			else: 
				update_paranoia(-fear_gain * delta)
		State.WALKING:
			const fear_gain = .05
			if close_fire:
				update_paranoia(3 * -fear_gain * delta)
			else:
				update_paranoia(fear_gain * delta)
			position = position.move_toward(target_point, speed * delta)
			if (position - last_pos).normalized().dot(Vector2(-1, 0)) > 0:
				sprite.flip_h = true
			else: sprite.flip_h = false
			last_pos = position
			if wandering and target_point.distance_to(global_position) < 1.0:
				begin_idle()
		State.FLEEING:
			#const fear_gain = .01
			if inhabited:
				position = position.move_toward(get_local_mouse_position(), speed * delta * FLEE_SPEED_MOD)
			else:
				position = position.move_toward(target_point, speed * delta * FLEE_SPEED_MOD)
			if paranoia < 0.9:
				begin_walking()
		State.COWERING:
			pass
		State.FREEZE:
			pass

func begin_idle():
	state = State.IDLE
	sprite.animation = "idle"
	sprite.play()
	wandering = false
	await get_tree().create_timer(4.0).timeout
	begin_walking()

func begin_walking():
	state = State.WALKING
	sprite.animation = "walk"
	sprite.play()
	sprite.material.set_shader_parameter("flashing", false)
	follow_random_campfire()

func begin_fleeing():
	state = State.FLEEING
	sprite.animation = "flee"
	sprite.play()
	target_point = global_position + Vector2(wander_range, 0).rotated(randf() * 2 * PI)

func begin_cowering():
	state = State.COWERING
	if following_campfire:
		following_campfire.clear_npc(self)
	sprite.animation = "cower"
	sprite.play()
	sprite.material.set_shader_parameter("flashing", true)
	await get_tree().create_timer(cower_duration).timeout
	sprite.material.set_shader_parameter("flashing", false)
	begin_freeze()

func begin_freeze():
	state = State.FREEZE
	sprite.animation = "idle"
	sprite.pause()
	await get_tree().create_timer(1.0).timeout
	begin_idle()

func is_fire_close():
	return following_campfire and following_campfire.global_position.distance_squared_to(global_position) < 4000.0

func on_wander_timeout(): 
	close_fire = is_fire_close()
	if state == State.WALKING and not wandering and close_fire:
		var rand = randf_range(0, 1)
		if rand <= wander_tendency:
			wander()

