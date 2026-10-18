extends CharacterBody3D


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed == true:
			get_parent_node_3d().playAnim("slap")
	#if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed == true:
		#print("Rclick")
		#get_parent_node_3d().get_child(0).reject_dialogue()
