extends Camera3D

@onready var camera_3d = $Camera3D

var camera
var cameraLeft = false
var cameraRight = false
var cameraUp = false
var cameraDown = false


const CAMERA_SENS = 0.03

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#var pos = Vector2(0,0)

	#get_viewport().warp_mouse(pos)
	
	if cameraLeft:
		var mousePos = get_viewport().get_mouse_position()
		var res = get_viewport().get_visible_rect().size
		if mousePos.x < res.x/4:
			rotation.y += CAMERA_SENS
			#rotation.x = clamp(rotation.x, -0.5, 1.2)
		else:
			cameraLeft = false
	if cameraRight:
		var mousePos = get_viewport().get_mouse_position()
		var res = get_viewport().get_visible_rect().size
		if mousePos.x > (res.x - res.x/4):
			rotation.y -= CAMERA_SENS
		else:
			cameraRight = false
			
	if cameraUp:
		var mousePos = get_viewport().get_mouse_position()
		var res = get_viewport().get_visible_rect().size
		if mousePos.y < res.y/4:
			rotation.x += CAMERA_SENS
			#rotation.x = clamp(rotation.x, -0.5, 1.2)
		else:
			cameraUp = false
	if cameraDown:
		var mousePos = get_viewport().get_mouse_position()
		var res = get_viewport().get_visible_rect().size
		if mousePos.y > (res.y - res.y/4):
			rotation.x -= CAMERA_SENS
		else:
			cameraDown = false


const RAY_LENGTH = 1000



#func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	#
func _input(event):
	if event.is_action_pressed("ui_cancel"): get_tree().quit()
	
	if event is InputEventMouseMotion:
		var mousePos = get_viewport().get_mouse_position()
		var res = get_viewport().get_visible_rect().size
		if mousePos.x < res.x/4:
			cameraLeft = true
		if mousePos.x > (res.x - res.x/4):
			cameraRight = true
		if mousePos.y < res.y/4:
			cameraUp = true
		if mousePos.y > (res.y - res.y/4):
			cameraDown = true
		
