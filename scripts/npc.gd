extends Area2D

class_name NPC

enum State {IDLE, WALKING, FLEEING, COWERING, FREEZE}

var state : State = State.WALKING

@export var speed := 30.0
@export var wander_tendency := 0.03 # 0.0 to 1.0, likelyhood to leave campfire and walk in a random direction 
var paranoia := 0.0
var display_paranoia := 0.0
var max_paranoia := 1.0
var can_cower = true
var cower_duration = 1.5
var cower_cooldown = 5.0
var last_pos : Vector2 = Vector2(0, 0)
var wander_range := 180.0
var inhabited = false
var flashing = false
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
var rumor_ready = false
var scream_ready = false
var rumor_cooldown = 10.0
var scream_cooldown = 10.0
var rumor_on_cooldown = false
var scream_on_cooldown = false
var rumor_scene : PackedScene = preload("res://scenes/npcs/rumor.tscn") 
var scream_scene : PackedScene = preload("res://scenes/npcs/scream.tscn") 
@onready var abilities_node = $Abilities
@onready var game : Game = get_tree().get_first_node_in_group("game")


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

func _cast_ability_on_input():
	scream_ready = flashing
	rumor_ready = paranoia >= 0.5
	if Input.is_action_just_pressed("action") and inhabited:
		if scream_ready and not scream_on_cooldown:
			scream()
		elif rumor_ready and not rumor_on_cooldown and not scream_ready:  
			rumor()

func scream():
	var new_scream : Scream = scream_scene.instantiate()
	new_scream.creator = self
	new_scream.global_position = global_position
	abilities_node.add_child(new_scream)
	scream_on_cooldown = true
	can_cower = false
	begin_freeze()
	await get_tree().create_timer(scream_cooldown).timeout
	scream_on_cooldown = false
	can_cower = true

func rumor():
	var new_rumor : Rumor = rumor_scene.instantiate()
	new_rumor.creator = self
	new_rumor.global_position = global_position
	abilities_node.add_child(new_rumor)
	rumor_on_cooldown = true
	begin_freeze()
	await get_tree().create_timer(rumor_cooldown).timeout
	rumor_on_cooldown = false

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

func get_random_campfire_pos():
	var campfires : Array = get_tree().get_nodes_in_group("campfire")
	return campfires[randi_range(0, campfires.size() - 1)].global_position

func clamp_vec2_to_level_dims(vec2):
	var level_dims : Vector2
	match game.current_level:
		Game.CurrentLevel.Level0:
			level_dims = Level.level0_dims
	var x = level_dims.x
	var y = level_dims.y
	vec2.x = clamp(vec2.x, -x, x)
	vec2.y = clamp(vec2.y, -y, y)
	return vec2

func wander():
	if following_campfire:
		following_campfire.clear_npc(self)
	target_point = global_position + Vector2(wander_range, 0).rotated(randf() * 2 * PI)
	target_point = clamp_vec2_to_level_dims(target_point)
	wandering = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_act_on_state(delta)
	_set_shader_params()
	_cast_ability_on_input()
	clamp_pos_to_level_dims()

func clamp_pos_to_level_dims():
	# limit position to screen edge
	var level_dims : Vector2
	match game.current_level:
		Game.CurrentLevel.Level0:
			level_dims = Level.level0_dims
	var x = level_dims.x
	var y = level_dims.y
	global_position.x = clamp(global_position.x, -x, x)
	global_position.y = clamp(global_position.y, -y, y)

func _set_shader_params():
	sprite.material.set_shader_parameter("fear_progress", paranoia)


func update_paranoia(val):
	if player.state == Player.State.PLANNING:
		pass
	else:
		paranoia += val
		paranoia = clampf(paranoia, 0, max_paranoia)

func _act_on_state(delta):
	match state:
		State.IDLE:
			const fear_gain = .05
			if not close_fire:
				if not rumor_on_cooldown:
					if inhabited:
						update_paranoia(fear_gain * 2 * delta)
					else:
						update_paranoia(fear_gain * delta)
			else: 
				update_paranoia(-fear_gain * delta)
			if paranoia == max_paranoia:
				begin_fleeing()
			
		State.WALKING:
			const fear_gain = .05
			if close_fire:
				update_paranoia(3 * -fear_gain * delta)
			else:
				if inhabited:
					update_paranoia(fear_gain * 2 * delta)
				else: update_paranoia(fear_gain * delta)
			position = position.move_toward(target_point, speed * delta)
			if (position - last_pos).dot(Vector2(-1, 0)) > 0:
				sprite.flip_h = true
			else: sprite.flip_h = false
			last_pos = position
			if wandering and target_point.distance_to(global_position) < 1.0:
				begin_idle(4.0)
			if paranoia == max_paranoia:
				begin_fleeing()
		State.FLEEING:
			const fear_loss_near_fire = .1
			if inhabited:
				position = position.move_toward(get_global_mouse_position(), speed * delta * FLEE_SPEED_MOD)
			else:
				position = position.move_toward(target_point, speed * delta * FLEE_SPEED_MOD)
				if target_point.distance_squared_to(global_position) < 1.0:
					target_point = get_random_campfire_pos()
			if close_fire:
				update_paranoia(-fear_loss_near_fire * delta)
			if paranoia < 0.9:
				begin_idle(2.5)
		State.COWERING:
			pass
		State.FREEZE:
			pass

func begin_idle(duration):
	state = State.IDLE
	sprite.animation = "idle"
	sprite.play()
	wandering = false
	sprite.material.set_shader_parameter("flashing", false)
	flashing = false
	scream_ready = false
	await get_tree().create_timer(duration).timeout
	if state == State.IDLE:
		begin_walking()

func begin_walking():
	state = State.WALKING
	sprite.animation = "walk"
	sprite.play()
	sprite.material.set_shader_parameter("flashing", false)
	flashing = false
	follow_random_campfire()
	wandering = false

func begin_fleeing():
	if following_campfire:
		following_campfire.clear_npc(self)
	state = State.FLEEING
	scream_ready = true
	sprite.animation = "flee"
	sprite.play()
	sprite.material.set_shader_parameter("flashing", true)
	flashing = true
	if close_fire: # run from fire irrationally
		target_point = global_position + Vector2(wander_range, 0).rotated(randf() * 2 * PI)

func begin_cowering():
	if can_cower:
		state = State.COWERING
		if following_campfire:
			following_campfire.clear_npc(self)
		sprite.animation = "cower"
		sprite.play()
		sprite.material.set_shader_parameter("flashing", true)
		flashing = true
		await get_tree().create_timer(cower_duration).timeout
		if state == State.COWERING:
			sprite.material.set_shader_parameter("flashing", false)
			flashing = false
			begin_freeze()
	else: begin_freeze()

func begin_freeze():
	state = State.FREEZE
	sprite.animation = "idle"
	sprite.pause()
	await get_tree().create_timer(1.5).timeout
	if state == State.FREEZE:
		if paranoia < 1.0:
			begin_idle(1.0)
		else: begin_fleeing()

func is_fire_close():
	const close = 4000.0
	if following_campfire:
		return following_campfire.global_position.distance_squared_to(global_position) < close
	else:
		return get_random_campfire_pos().distance_squared_to(global_position) < close


func on_wander_timeout(): 
	close_fire = is_fire_close()
	if state == State.WALKING and not wandering and close_fire:
		var rand = randf_range(0, 1)
		if rand <= wander_tendency:
			wander()

