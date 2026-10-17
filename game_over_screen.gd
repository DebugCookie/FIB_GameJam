extends ColorRect
class_name GameOverScreen

@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton

signal restart_requested

func _ready() -> void:
	restart_button.pressed.connect(func(): restart_requested.emit())
	quit_button.pressed.connect(func(): get_tree().quit())
