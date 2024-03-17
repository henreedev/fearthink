extends CanvasLayer
class_name HUD

@onready var player : Player = get_tree().get_first_node_in_group("player")
@onready var fear_bar : TextureProgressBar = $FearBar
@onready var sprite : AnimatedSprite2D = $Control/AnimatedSprite2D
@onready var level : Level = get_tree().get_first_node_in_group("level")
@onready var npcs = get_tree().get_nodes_in_group("npc")

var level_index = 1

var fear_ratio = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func show_fear_bar():
	fear_bar.visible = true
	create_tween().tween_property(fear_bar, "position", Vector2(160, 10), 1.0).set_trans(Tween.TRANS_CUBIC).from(Vector2(160, -30))

func hide_fear_bar():
	if fear_bar:
		fear_bar.visible = false

func update_fear_bar(delta):
	const rate = 1.0
	fear_bar.value = lerp(fear_bar.value, fear_ratio, rate * delta)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not level.transitioning:
		if fear_bar.visible:
			update_fear_bar(delta)
		var npc : NPC = player.locked_in_npc if player.locked_in_npc else player.inhabiting_npc
		if npc and is_instance_valid(npc):
			if npc.scream_ready and not npc.scream_on_cooldown:
				sprite.animation = "scream"
				sprite.modulate = Color(1.0, 1.0, 1.0, 0.8)
			elif npc.scream_ready:
				sprite.animation = "scream"
				sprite.modulate = Color(0.4, 0.4, 0.4, 0.4)
			elif npc.rumor_ready and not npc.rumor_on_cooldown:
				sprite.animation = "rumor"
				sprite.modulate = Color(1.0, 1.0, 1.0, 0.8)
			elif npc.rumor_ready:
				sprite.animation = "rumor"
				sprite.modulate = Color(0.4, 0.4, 0.4, 0.4)
			else:
				sprite.animation = "rumor"
				sprite.modulate = Color(0.4, 0.4, 0.4, 0.2)
				sprite.visible = true
		else: 
			sprite.visible = false



func update_fear_vals():
	var total_paranoia = 0.0
	var max_paranoia = 0.0
	for npc : NPC in npcs:
		max_paranoia += npc.max_paranoia
		total_paranoia += npc.paranoia
	print("max = " + str(max_paranoia))
	print("total = " + str(total_paranoia))
	fear_ratio = clampf(total_paranoia / (max_paranoia * 0.75), 0, 1)
	if fear_ratio == 1.0:
		player.begin_planning()
		level.load_new_level(level_index)
		level_index += 1
		fear_ratio = 0.0



func _on_timer_timeout():
	update_fear_vals()
