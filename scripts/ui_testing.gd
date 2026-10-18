extends CanvasLayer

# UI-referenser för mätarna
@onready var employee_bar: ProgressBar = %Employeebar
@onready var work_bar: ProgressBar = %WorkBar

# NYTT: Referenser till textetiketterna för mätarna
@onready var employee_bar_label: Label = %EmployeeBarLabel
@onready var work_bar_label: Label = %WorkBarLabel

@onready var dialogue_label: Label = $VBoxContainer/DialogueLabel
@onready var yes_button: Button = $VBoxContainer/ButtonContainer/YesButton
@onready var no_button: Button = $VBoxContainer/ButtonContainer/NoButton
@onready var character_label: Label = $VBoxContainer/CharacterLabel 

# Stats
var employee_morale: int = 50
var work_morale: int = 50

var manager: DialogueManager
const DIALOGUE_FILE_PATH = "Json/dialogue.json"

var current_character: String = ""
var current_dialogue: Dictionary = {}

func _ready() -> void:
	manager = DialogueManager.new()
	if not manager.load_dialogue_file(DIALOGUE_FILE_PATH):
		dialogue_label.text = "Fel: Kunde inte ladda dialogfilen."
		return
	
	yes_button.pressed.connect(_on_yes_button_pressed)
	no_button.pressed.connect(_on_no_button_pressed)
	
	update_ui_bars()
	display_next_dialogue()

# Uppdaterar mätarna och deras tillhörande textetiketter
func update_ui_bars() -> void:
	employee_morale = clamp(employee_morale, 0, 100)
	work_morale = clamp(work_morale, 0, 100)
	
	# Uppdatera själva mätarstaplarna
	employee_bar.value = employee_morale
	work_bar.value = work_morale
	
	# Korrekt textuppdatering via de externa textetiketterna
	employee_bar_label.text = "Employee Morale: %d%%" % employee_morale
	work_bar_label.text = "Work Morale: %d%%" % work_morale

# (Resten av dina funktioner som display_next_dialogue, _on_yes_button_pressed osv. förblir likadana)
func display_next_dialogue() -> void:
	var characters = manager.get_character_names()
	if characters.is_empty():
		dialogue_label.text = "Inga karaktärer hittades i filen."
		return
		
	current_character = characters[randi() % characters.size()]
	
	var categories = manager.get_character_categories(current_character)
	if categories.is_empty(): return
	var random_category = categories[randi() % categories.size()]
	
	current_dialogue = manager.roll_weighted_item(current_character, random_category)
	
	if not current_dialogue.is_empty():
		character_label.text = "Speaker: %s" % current_character
		dialogue_label.text = "\"%s\"" % current_dialogue.get("text", "")

func _on_yes_button_pressed() -> void:
	if current_dialogue.is_empty(): return
	
	var morale_impact = current_dialogue.get("morale_impact", {"employee": 0, "work": 0})
	employee_morale += int(morale_impact.get("employee", 0))
	work_morale += int(morale_impact.get("work", 0))
	
	update_ui_bars()
	display_next_dialogue()

func _on_no_button_pressed() -> void:
	if current_dialogue.is_empty(): return
	
	var morale_impact = current_dialogue.get("morale_impact", {"employee": 0, "work": 0})
	employee_morale -= int(morale_impact.get("employee", 0))
	work_morale -= int(morale_impact.get("work", 0))
	
	update_ui_bars()
	display_next_dialogue()
