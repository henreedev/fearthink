extends CanvasLayer

@onready var player : Player = get_tree().get_first_node_in_group("player")
@onready var npc_bar : TextureProgressBar = $TextureProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var npc : NPC = player.inhabiting_npc 
	if npc:
		npc_bar.value = npc.paranoia * 100.0 
	else: 
		npc_bar.value = 0.0
