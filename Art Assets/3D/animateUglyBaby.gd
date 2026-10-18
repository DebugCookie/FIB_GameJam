extends Node3D
@onready var anim_play: AnimationPlayer = $AnimationPlayer

func playAnim(animation: String) -> void:
	anim_play.play(animation)
	anim_play.queue("idle")
	anim_play.queue("idle")
	anim_play.queue("idle")
	anim_play.queue("idle")
	anim_play.queue("idle")
	anim_play.queue("idle")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	playAnim("idle")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var random_roll = randi() % 1000
	if random_roll <= 1:
		playAnim("jumptug")
		
	if (anim_play.get_queue().size() < 6):#this is true when idle is not playing (kinda)
		pass
	#print(anim_play.get_queue().size())


#func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			#print("Lclick")
		#if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed == true:
			#print("Rclick")
			#get_parent_node_3d().get_child(0).reject_dialogue()
