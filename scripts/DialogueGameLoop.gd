extends Node3D

@onready var global_morale_ui: GlobalMorale3D = $GlobalMorale3D
@onready var characters_container: Node3D = $Characters
@onready var game_ui: GameUI = $GameUI 

@export var day_duration_minutes: float = 2.0  
@export var money_quota: int = 30000           
@export var loading_screen_duration: float = 3.0 

var current_day: int = 1                       
var current_money: int = 0 
var company_happiness: int = 100 

var time_remaining_seconds: float = 0.0
var total_day_seconds: float = 0.0

var manager: DialogueManager
const DIALOGUE_FILE_PATH = "res://Json/dialogue.json"
var is_game_over: bool = false

func _ready() -> void:
	manager = DialogueManager.new()
	if not manager.load_dialogue_file(DIALOGUE_FILE_PATH):
		print("Kunde inte ladda JSON-dialogbanken!")
		return
		
	total_day_seconds = day_duration_minutes * 60.0
	time_remaining_seconds = total_day_seconds
	
	game_ui.next_day_started.connect(start_next_day)
		
	
	_start_first_day()

func _start_first_day() -> void:
	await game_ui.trigger_loading_screen(current_day, loading_screen_duration)
	
	update_ui()
	
	for character in characters_container.get_children():
		if character is Character3D:
			character.start_character_loop(manager, self)

func _process(delta: float) -> void:
	if is_game_over: return
	
	if time_remaining_seconds > 0:
		time_remaining_seconds -= delta
		global_morale_ui.update_time_and_round(current_day, time_remaining_seconds)
	else:
		time_remaining_seconds = 0
		global_morale_ui.update_time_and_round(current_day, 0)
		check_win_conditions()

func modify_game_stats(changes: Dictionary) -> void:
	if is_game_over: return
	
	current_money += int(changes.get("Money", 0))
	company_happiness += int(changes.get("Moral", 0))
	
	company_happiness = clamp(company_happiness, 0, 100)
	update_ui()
	
	if company_happiness <= 0:
		trigger_loss("Personalen har fått nog. Företagets Moral nådde 0%!")

func update_ui() -> void:
	global_morale_ui.update_morale_display(company_happiness, current_money, money_quota)

func check_win_conditions() -> void:
	if current_money >= money_quota:
		print("Dagen avklarad! Öppnar vinstmenyn.")
		game_ui.show_day_win(current_money, money_quota)
	else:
		trigger_loss("Tiden tog slut! Du nådde inte pengakvoten på $%d. Du fick bara ihop $%d." % [money_quota, current_money])

func start_next_day() -> void:
	current_day += 1
	current_money = 0 
	time_remaining_seconds = total_day_seconds 
	
	money_quota = int(money_quota * 1.4)
	
	update_ui()
	
	await game_ui.trigger_loading_screen(current_day, loading_screen_duration)
	print("--- STARTAR DAG %d (Ny kvot: $%d) ---" % [current_day, money_quota])

func trigger_loss(reason: String) -> void:
	is_game_over = true
	game_ui.show_game_over()
