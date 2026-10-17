extends Camera3D

@onready var camera_3d = $Camera3D

var camera

const CAMERA_SENS = 0.003

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var pos = Vector2(0,0)

	get_viewport().warp_mouse(pos)
	pass


const RAY_LENGTH = 1000

#func _physics_process(delta):
	#var space_state = get_world_3d().direct_space_state
	#var cam = $Camera3D
	#var mousepos = get_viewport().get_mouse_position()
#
 	#
#
	##var origin = cam.project_ray_origin(mousepos)
	#var origin = cam.get_camera_pos()
	#var end = origin + cam.FORWARD * RAY_LENGTH
	#var query = PhysicsRayQueryParameters3D.create(origin, end)
	#query.collide_with_areas = true
#
	#var result = space_state.intersect_ray(query)




#func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	#
#func _input(event):
	#if event.is_action_pressed("ui_cancel"): get_tree().quit()
	#
	#if event is InputEventMouseMotion:
		#rotation.y -= event.relative.x * CAMERA_SENS
		#rotation.x -= event.relative.y * CAMERA_SENS
		#rotation.x = clamp(rotation.x, -0.5, 1.2)
