extends Marker2D
class_name Player

enum State {INHABITING, TRAVELLING, PLANNING, READY}
var state : State = State.READY
var drag_dist := 30.0
var pan_speed := 50.0
var level_size : Vector2 
@onready var game : Game = get_tree().get_first_node_in_group("game")
@onready var selector : Area2D = $Selector
@onready var reticle : AnimatedSprite2D = $Selector/Reticle
@onready var swirl : AnimatedSprite2D = $Selector/Swirl
@onready var ghost : Line2D = $Ghost
@onready var level : Level = get_tree().get_first_node_in_group("level")
var selected_npcs = []
var selected_npc : NPC 
var selection_range_sqrd := 125.0 * 125.0
var locked_in_npc : NPC
var inhabiting_npc : NPC 
var can_exit_planning = false

# Called when the node enters the scene tree for the first time.
func _ready():
	begin_planning()

func _act_on_state(delta):
	match state:
		State.PLANNING:
			_move_screen_at_edge(delta)
			ghost.visible = true
			_exit_planning_on_input()
		State.READY:
			ghost.visible = false
			_move_screen_at_edge(delta)
			_update_selector()
			_display_selected_npc()
			_enter_on_input()
		State.TRAVELLING:
			_update_selector()
			_display_selected_npc()
			_follow_host()
			_enter_on_input()
			if (reticle.animation == "choose" or reticle.animation == "choose_faded") and reticle.frame == 2:
				reticle.pause()
		State.INHABITING:
			_update_selector()
			_display_selected_npc()
			_follow_host()
			_enter_on_input()

func _exit_planning_on_input():
	if Input.is_action_just_pressed("enter") and can_exit_planning:
		begin_ready()

func _follow_host():
	if locked_in_npc:
		global_position = locked_in_npc.global_position
	elif inhabiting_npc:
		global_position = inhabiting_npc.global_position

func _enter_on_input():
	if Input.is_action_just_pressed("enter") and selected_npc:
		locked_in_npc = selected_npc
		swirl.animation = "enter"
		begin_travelling()

func _move_screen_at_edge(delta):
	var mouse_pos := get_local_mouse_position()
	var adj_pos = Vector2(mouse_pos.x, mouse_pos.y * 1.78) # adjust for aspect ratio limiting vertical movement
	var mag = adj_pos.length()
	if mag > drag_dist:
		var extra_speed = mag / drag_dist
		position = position.move_toward(position + mouse_pos, extra_speed * pan_speed * delta)
	clamp_pos_to_level_dims()

func _update_selector():
	var mouse_pos := get_local_mouse_position()
	selector.position = mouse_pos
	var best_npc : NPC
	var best_flashing_npc : NPC 
	var best_dist := 999999.0
	var best_flashing_dist := 999999.0
	for npc : NPC in selected_npcs:
		var flashing = npc.state == NPC.State.COWERING
		#Conditions to select: 
		#0. is not the currently inhabited npc
		if npc.inhabited: continue;
		#1. must be in range 
		var player_dist = npc.global_position.distance_squared_to(global_position)
		if player_dist > selection_range_sqrd: continue;
		#2. prioritize flashing
		var dist = npc.global_position.distance_squared_to(selector.global_position)
		if flashing and dist < best_flashing_dist:
			best_flashing_dist = dist
			best_flashing_npc = npc
			break; # non-flashing case doesn't matter if it's flashing
		if dist < best_dist:
			best_dist = dist
			best_npc = npc
	# Decide on the best npc to select
	if best_flashing_npc:
		selected_npc = best_flashing_npc 
	else:
		selected_npc = best_npc if best_npc else null
	_update_swirl()

func _update_swirl():
	swirl.play()
	if locked_in_npc:
		global_position = locked_in_npc.global_position
		swirl.global_position = locked_in_npc.global_position
	elif inhabiting_npc:
		swirl.global_position = inhabiting_npc.global_position
	elif selected_npc:
		swirl.global_position = selected_npc.global_position
	else: swirl.position = Vector2(0, 0)

func _display_selected_npc():
	if locked_in_npc:
		reticle.visible = true
		reticle.global_position = locked_in_npc.global_position
		if state == State.TRAVELLING:
			reticle.animation = "choose_faded"
		else: reticle.animation = "choose"
		reticle.play()
	elif selected_npc:
		reticle.visible = true
		reticle.global_position = selected_npc.global_position
		reticle.animation = "normal"
		reticle.play()
	else:
		reticle.visible = false

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

func begin_inhabiting():
	swirl.animation = "inhabit"
	# inhabiting_npc should be populated
	if inhabiting_npc:
		inhabiting_npc.inhabited = true
	state = State.INHABITING

func begin_travelling():
	state = State.TRAVELLING
	#  zoom in a bit more
	create_tween().tween_property($Camera2D, "zoom", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func begin_planning():
	state = State.PLANNING
	ghost.visible = true
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.0)
	swirl.visible = false
	reticle.visible = false
	var tween = create_tween()
	tween.tween_property($Camera2D, "zoom", Vector2(0.5, 0.5), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(level, "hue_shift", 0.0, 3.0)
	tween.tween_property(level, "darken", 0.0, 3.0)
	tween.tween_property(ghost, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0).from(Color(1.0, 1.0, 1.0, 0.0)).set_trans(Tween.TRANS_CIRC).set_delay(1.0)
	
	await get_tree().create_timer(5.0).timeout
	can_exit_planning = true
	

func begin_ready():
	state = State.READY
	var tween = create_tween().set_parallel(true)
	tween.tween_property($Camera2D, "zoom", Vector2(0.8, 0.8), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ghost, "modulate", Color(1.0,1.0,1.0,0.0), 1.0)
	tween.tween_property(level, "hue_shift", 0.33, 3.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(level, "darken", 0.7, 1.0).set_trans(Tween.TRANS_CUBIC)
	level.transitioning = true
	tween.tween_property(level, "campfires_visible", true, 0.0)
	tween.tween_property(level, "campfire_scale", 1.0, 3.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	create_tween().tween_property(ghost, "visible", false, 0.0)
	create_tween().tween_property(swirl, "visible", true, 0.0)
	await get_tree().create_timer(3.0).timeout
	level.transitioning = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_act_on_state(delta)


func _on_selector_area_entered(area):
	if area is NPC:
		selected_npcs.append(area)


func _on_selector_area_exited(area):
	if area is NPC:
		selected_npcs.erase(area)

func _on_swirl_animation_finished():
	if swirl.animation == "enter":
		if inhabiting_npc:
			inhabiting_npc.inhabited = false
		inhabiting_npc = locked_in_npc
		locked_in_npc = null
		begin_inhabiting()


func _on_reticle_animation_finished():
	if reticle.animation == "choose" or reticle.animation == "choose_faded":
		reticle.pause()
