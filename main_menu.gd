extends ColorRect
class_name MainMenu

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton

const GAME_SCENE_PATH = "res://maxTestScene.tscn" 

func _ready() -> void:
	get_tree().paused = false
	
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(func(): get_tree().quit())

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
