extends Marker2D

enum State {INHABITING, TRAVELLING, PLANNING, READY}
var state : State = State.PLANNING

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _act_on_state(delta):
	match state:
		State.PLANNING:
			pass
		State.READY:
			pass
		State.TRAVELLING:
			pass
		State.INHABITING:
			pass 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_act_on_state(delta)



