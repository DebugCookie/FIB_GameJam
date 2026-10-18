extends Camera3D

@onready var hand_sprite: AnimatedSprite2D = $Hand/HandBase/AnimatedSprite2D
@onready var sfx_yes: AudioStreamPlayer3D = $SFX_Yes
@onready var sfx_no: AudioStreamPlayer3D = $SFX_No

var camera
var cameraLeft = false
var cameraRight = false
var cameraUp = false
var cameraDown = false

const CAMERA_SENS = 0.07

func _ready() -> void:
	if hand_sprite:
		if hand_sprite.animation_finished.is_connected(_on_hand_animation_finished):
			hand_sprite.animation_finished.disconnect(_on_hand_animation_finished)
		hand_sprite.animation_finished.connect(_on_hand_animation_finished)
		
		hand_sprite.play("Idle")

func _on_hand_animation_finished() -> void:
	if hand_sprite:
		var current_anim = hand_sprite.animation
		if current_anim == "Yes" or current_anim == "No":
			hand_sprite.play("Idle")

func _process(delta: float) -> void:
	if cameraLeft:
		var mousePos = get_viewport().get_mouse_position()
		var res = get_viewport().get_visible_rect().size
		if mousePos.x < res.x/10:
			rotation.y += CAMERA_SENS
			rotation.y = clamp(rotation.y, -2, 2)
		else:
			cameraLeft = false
	if cameraRight:
		var mousePos = get_viewport().get_mouse_position()
		var res = get_viewport().get_visible_rect().size
		if mousePos.x > (res.x - res.x/10):
			rotation.y -= CAMERA_SENS
			rotation.y = clamp(rotation.y, -2, 2)
		else:
			cameraRight = false
			


const RAY_LENGTH = 1000

func _input(event):
	if event.is_action_pressed("ui_cancel"): get_tree().quit()
	
	if event is InputEventMouseButton and event.pressed:
		if hand_sprite:
			if event.button_index == MOUSE_BUTTON_LEFT:
				hand_sprite.play("Yes")
				sfx_yes.play()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				hand_sprite.play("No")
				sfx_no.play()
	
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
