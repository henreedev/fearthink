extends Area2D

class_name NPC

enum State {IDLE, WALKING, FLEEING, COWERING}

@export var speed := 10.0
@export var wander_tendency := 0.1 # 0.0 to 1.0, likelyhood to leave campfire and walk in a random direction 
var paranoia := 0.0
var max_paranoia := 100.0
var can_cower = true
var cower_duration = 1.5
var cower_cooldown = 5.0

# Campfire following variables
var following_campfire : Campfire
var target_point : Vector2
var point_index : int

# Called when the node enters the scene tree for the first time.
func _ready():
	follow_random_campfire()

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
	_act_on_state()


func _act_on_state():
	pass
