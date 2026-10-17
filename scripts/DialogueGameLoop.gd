extends Node3D

@onready var characters_container: Node3D = $Characters
@onready var global_morale_ui: GlobalMorale3D = $GlobalMorale3D

var employee_morale: int = 50
var work_morale: int = 50

var manager: DialogueManager
const DIALOGUE_FILE_PATH = "res://Json/dialogue.json"

func _ready() -> void:
	manager = DialogueManager.new()
	if not manager.load_dialogue_file(DIALOGUE_FILE_PATH):
		print("Kunde inte ladda JSON-dialogbanken!")
		return
		
	global_morale_ui.update_morale_display(employee_morale, work_morale)
	
	for character in characters_container.get_children():
		if character is Character3D:
			character.start_character_loop(manager, self)

func apply_morale_impact(is_yes: bool, impact: Dictionary) -> void:
	var modifier = 1 if is_yes else -1
	
	employee_morale += int(impact.get("employee", 0)) * modifier
	work_morale += int(impact.get("work", 0)) * modifier
	
	employee_morale = clamp(employee_morale, 0, 100)
	work_morale = clamp(work_morale, 0, 100)
	
	global_morale_ui.update_morale_display(employee_morale, work_morale)
