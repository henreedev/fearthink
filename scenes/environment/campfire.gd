extends StaticBody2D
class_name Campfire


@onready var path : Path2D = $Path2D
@export var num_points = 10
@export var random_offset := 10.0
var points_dict = {}
var progress := 0.0 # 0 to 1
var progress_rate := 0.125 # 45 deg per sec

# inner class, acts like a struct, very pog
class PointInfo:
	var progressOffset : float
	var randomOffset : Vector2
	var currentFollowingNpcs = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_create_follow_points()
	var npc : NPC = NPC.new()
	follow_random_point(npc)

func _create_follow_points():
	for i in range(num_points):
		var follow_point : PathFollow2D = PathFollow2D.new()
		path.add_child(follow_point)
		points_dict[follow_point] = PointInfo.new()
		points_dict[follow_point].randomOffset = Vector2(randf_range(-random_offset, random_offset), randf_range(-random_offset, random_offset))
		points_dict[follow_point].progressOffset = float(i) / float(num_points)
		var sprite = Sprite2D.new()
		sprite.texture = load("res://assets/image/fearthink-mc.png")
		follow_point.add_child(sprite)
	

func follow_random_point(npc : NPC): 
	# num_points should be >0
	var length = points_dict.size() # should be == num_points
	var rand = randi_range(0, length - 1)
	var randomPoint : PointInfo = points_dict.values()[rand] # note that multiple npcs can follow same point
	randomPoint.currentFollowingNpcs.append(npc)
	npc.point_index = rand
	npc.following_campfire = self
	npc.target_point = points_dict.keys()[rand].global_position

func clear_npc(npc : NPC):
	var point_to_clear : PointInfo = points_dict.values()[npc.point_index]
	point_to_clear.currentFollowingNpcs.erase(npc)
	npc.following_campfire = null
	npc.target_point = Vector2()
	npc.point_index = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	set_npc_points()
	rotate_points(delta)

func set_npc_points():
	for follow_point : PathFollow2D in points_dict.keys():
		var point : PointInfo = points_dict[follow_point]
		for npc : NPC in point.currentFollowingNpcs:
			npc.target_point = follow_point.global_position + point.randomOffset

func rotate_points(delta):
	progress += delta * progress_rate
	progress = fmod(progress, 1.0)
	for follow_point : PathFollow2D in points_dict.keys():
		follow_point.progress_ratio = progress + points_dict[follow_point].progressOffset
	
