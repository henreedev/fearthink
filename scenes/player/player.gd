extends Marker2D

enum State {INHABITING, TRAVELLING, PLANNING, READY}
var state : State = State.PLANNING
var drag_dist := 30.0
var pan_speed := 50.0
var level_size : Vector2 
@onready var game : Game = get_tree().get_first_node_in_group("game")
@onready var selector : Area2D = $Selector
var selected_npcs = []
var selected_npc : NPC 
var selection_range := 50.0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _act_on_state(delta):
	match state:
		State.PLANNING:
			_move_screen_at_edge(delta)
			_update_selector()
		State.READY:
			_move_screen_at_edge(delta)
			_update_selector()
		State.TRAVELLING:
			pass
		State.INHABITING:
			pass 

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
		#1. must be in range 
		#2. prioritize flashing
		var dist = npc.global_position.distance_squared_to(selector.global_position)
		if dist < best_dist:
			best_dist = dist
			best_npc = npc
		if flashing and dist < best_flashing_dist:
			best_flashing_dist = dist
			best_flashing_npc = npc
	if best_flashing_npc:
		selected_npc = best_flashing_npc 
	else:
		selected_npc = best_npc if best_npc else null
	if selected_npc:
		selected_npc.sprite.speed_scale = 10.0
	

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for npc : NPC in get_tree().get_nodes_in_group("npc"):
		npc.sprite.speed_scale = 1.0 # TODO remove
	_act_on_state(delta)


func _on_selector_area_entered(area):
	if area is NPC:
		selected_npcs.append(area)
		print("added")


func _on_selector_area_exited(area):
	if area is NPC:
		selected_npcs.erase(area)
		print("removed")
