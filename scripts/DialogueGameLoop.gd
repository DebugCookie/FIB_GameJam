extends Node3D

@onready var characters_container: Node3D = $Characters
@onready var global_morale_ui: GlobalMorale3D = $GlobalMorale3D

@export var day_duration_minutes: float = 2.0  
@export var money_quota: int = 500             

var current_day: int = 1                       # NY: Håller koll på vilket dygn vi är på
var current_money: int = 0
var company_happiness: int = 100 # Startar på max (100)

# NYTT: Interna tidtagarvariabler
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
		
	# NYTT: Initiera realtidsklockan baserat på dina inställda minuter
	total_day_seconds = day_duration_minutes * 60.0
	time_remaining_seconds = total_day_seconds
		
	update_ui()
	
	# BORTTAGEN: start_day_timer() behövs inte längre eftersom klockan tickar i _process nu!
	
	for character in characters_container.get_children():
		if character is Character3D:
			character.start_character_loop(manager, self)

# NYTT: Denna inbyggda loop körs varje bildruta och räknar ner sekunderna automatiskt
func _process(delta: float) -> void:
	if is_game_over: return
	
	if time_remaining_seconds > 0:
		# Ticka ner klockan baserat på speltid
		time_remaining_seconds -= delta
		# Skicka de exakta sekunderna och dygnet till din 3D-tavla
		global_morale_ui.update_time_and_round(current_day, time_remaining_seconds)
	else:
		# Tiden slog precis över till 0!
		time_remaining_seconds = 0
		global_morale_ui.update_time_and_round(current_day, 0)
		check_win_conditions()

func modify_game_stats(changes: Dictionary) -> void:
	if is_game_over: return
	
	current_money += int(changes.get("money", 0))
	company_happiness += int(changes.get("happiness", 0))
	
	company_happiness = clamp(company_happiness, 0, 100)
	
	update_ui()
	
	if company_happiness <= 0:
		trigger_loss("Personalen har fått nog. Företagets happiness nådde 0%!")

func update_ui() -> void:
	global_morale_ui.update_morale_display(company_happiness, current_money)

func check_win_conditions() -> void:
	if current_money >= money_quota:
		print("GRATTIS! Du klarade dagens kvot på %d! (Du fick ihop %d)" % [money_quota, current_money])
		# NYTT: I stället för att bara stanna spelet, starta nästa dag automatiskt
		start_next_day()
	else:
		trigger_loss("Tiden tog slut! Du nådde inte pengakvoten på %d." % money_quota)

func start_next_day() -> void:
	current_day += 1
	current_money = 0 
	time_remaining_seconds = total_day_seconds 
	
	money_quota += 250 
	
	update_ui()
	print("--- STARTAR DAG %d (Ny kvot: %d) ---" % [current_day, money_quota])

func trigger_loss(reason: String) -> void:
	is_game_over = true
	print("GAME OVER: ", reason)
