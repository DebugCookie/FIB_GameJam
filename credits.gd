
extends ColorRect
class_name Credits


@onready var back_button: Button = $BackButton

const MAIN_MENU_PATH = "res://main_menu.tscn"


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
