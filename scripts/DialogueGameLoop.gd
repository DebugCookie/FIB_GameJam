extends Node3D

@onready var characters_container: Node3D = $Characters
@onready var global_morale_ui: GlobalMorale3D = $GlobalMorale3D

@export var starting_employee_morale: int = 50
@export var starting_work_morale: int = 50

var employee_morale: int = 50
var work_morale: int = 50

var manager: DialogueManager
const DIALOGUE_FILE_PATH = "res://Json/dialogue.json"

func _ready() -> void:
	employee_morale = starting_employee_morale
	work_morale = starting_work_morale

	manager = DialogueManager.new()
	if not manager.load_dialogue_file(DIALOGUE_FILE_PATH):
		print("Kunde inte ladda JSON-dialogbanken!")
		return
		
	global_morale_ui.update_morale_display(employee_morale, work_morale)
	
	for character in characters_container.get_children():
		if character is Character3D:
			character.start_character_loop(manager, self)


func modify_global_morale(morale_change: Dictionary) -> void:
	employee_morale += int(morale_change.get("Morale", 0))
	work_morale += int(morale_change.get("Money", 0))
	
	# Håll mätarna säkra mellan 0 och 100
	employee_morale = clamp(employee_morale, 0, 100)
	work_morale = clamp(work_morale, 0, 100)
	
	# Uppdatera 3D UI-tavlan direkt
	global_morale_ui.update_morale_display(employee_morale, work_morale)
