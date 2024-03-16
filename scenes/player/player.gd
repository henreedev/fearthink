extends Marker2D

enum State {INHABITING, TRAVELLING, PLANNING, READY}
var state : State = State.PLANNING
var drag_dist := 30.0
var pan_speed := 50.0
var level_size : Vector2 
@onready var game : Game = get_tree().get_first_node_in_group("game")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _act_on_state(delta):
	match state:
		State.PLANNING:
			_move_screen_at_edge(delta)
		State.READY:
			_move_screen_at_edge(delta)
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
	_act_on_state(delta)
