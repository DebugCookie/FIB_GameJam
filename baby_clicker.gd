extends CharacterBody3D

func _on_area_3d_input_event(camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			print("Klickade SLAP på bebis via Area3D")
			get_parent_node_3d().playAnim("slap") 
			
			if camera and camera.has_method("play_hand_animation"):
				camera.play_hand_animation("Slap")
			
		elif event.button_index == MOUSE_BUTTON_LEFT:
			print("Klickade PET på bebis via Area3D")
			get_parent_node_3d().playAnim("jumptug")
			
			if camera and camera.has_method("play_hand_animation"):
				camera.play_hand_animation("Pet")
