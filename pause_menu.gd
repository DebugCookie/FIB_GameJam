extends ColorRect
class_name PauseMenu

@onready var resume_button: Button = %ResumeButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var quit_button: Button = %QuitButton

signal resume_requested
signal main_menu_requested

func _ready() -> void:
	resume_button.pressed.connect(func(): resume_requested.emit())
	main_menu_button.pressed.connect(func(): main_menu_requested.emit())
	quit_button.pressed.connect(func(): get_tree().quit())
