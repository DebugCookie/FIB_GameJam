
extends Node3D


# ==========================================
# NODE REFERENCES
# ==========================================

@onready var global_morale_ui: GlobalMorale3D = $GlobalMorale3D
@onready var characters_container: Node3D = $Characters
@onready var game_ui: GameUI = $GameUI

@onready var sfx_morale_negative: AudioStreamPlayer3D = $SFX_Morale_Negative
@onready var sfx_morale_positive: AudioStreamPlayer3D = $SFX_Morale_Positive
@onready var sfx_money_positive: AudioStreamPlayer3D = $SFX_Money_Positive
@onready var sfx_money_negative: AudioStreamPlayer3D = $SFX_Money_Negative


# ==========================================
# JANITOR REFERENCES
# Based on your actual scene hierarchy
# ==========================================

@onready var janitor_controller: JanitorController = $Characters/JanitorMoverScriptHolder
@onready var janitor_character: Character3D = $Characters/JanitorMoverScriptHolder/Janitor

# ==========================================
# GAME SETTINGS
# ==========================================

@export_group("Game Settings")

@export var day_duration_minutes: float = 2.0
@export var money_quota: int = 30000
@export var loading_screen_duration: float = 3.0


# ==========================================
# JANITOR SETTINGS
# ==========================================

@export_group("Janitor")
@export var enable_janitor_test: bool = true


# ==========================================
# GAME VARIABLES
# ==========================================

var current_day: int = 1
var current_money: int = 0
var company_happiness: int = 100

var time_remaining_seconds: float = 0.0
var total_day_seconds: float = 0.0

var manager: DialogueManager

const DIALOGUE_FILE_PATH: String = "res://Json/dialogue.json"

var is_game_over: bool = false
var day_active: bool = false


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:

	print("OFFICE: Initializing game")

	manager = DialogueManager.new()

	if not manager.load_dialogue_file(DIALOGUE_FILE_PATH):
		push_error("OFFICE: Could not load dialogue JSON.")
		return

	total_day_seconds = day_duration_minutes * 60.0
	time_remaining_seconds = total_day_seconds

	if game_ui:
		if not game_ui.next_day_started.is_connected(start_next_day):
			game_ui.next_day_started.connect(start_next_day)

	setup_janitor()

	_start_first_day()


# ==========================================
# JANITOR INITIALIZATION
# ==========================================

func setup_janitor() -> void:

	if not is_instance_valid(janitor_controller):
		push_error("OFFICE: JanitorMoverScriptHolder missing.")
		return

	if not is_instance_valid(janitor_character):
		push_error("OFFICE: Janitor character missing.")
		return

	janitor_character.character_name = "Janitor"
	janitor_character.is_janitor = true
	janitor_character.janitor_controller = janitor_controller

	# Character3D will connect the Bubble3D signals.
	# No duplicate connections here.

	print("OFFICE: Janitor references configured.")


# ==========================================
# START FIRST DAY
# ==========================================

func _start_first_day() -> void:

	day_active = false

	if game_ui:
		await game_ui.trigger_loading_screen(
			current_day,
			loading_screen_duration
		)

	update_ui()

	# Start ordinary NPC dialogue loops once.
	for character in characters_container.get_children():

		if character is Character3D:
			character.start_character_loop(manager, self)

	# Janitor is outside the Characters container.
	if is_instance_valid(janitor_character):

		if is_instance_valid(janitor_controller):

			# Allow scheduling from this point onward.
			day_active = true

			janitor_character.start_character_loop(
				manager,
				self
			)

			print("OFFICE: Janitor initialized.")
			print(
				"OFFICE: Bubble connected = ",
				is_instance_valid(janitor_controller.bubble)
			)
		else:
			day_active = true
			push_error("OFFICE: Janitor controller invalid.")
	else:
		day_active = true
		push_error("OFFICE: Janitor character invalid.")

	print("OFFICE: Day ", current_day, " started.")


# ==========================================
# GAME TIMER
# ==========================================

func _process(delta: float) -> void:

	if is_game_over or not day_active:
		return

	time_remaining_seconds = maxf(
		time_remaining_seconds - delta,
		0.0
	)

	if global_morale_ui:
		global_morale_ui.update_time_and_round(
			current_day,
			time_remaining_seconds
		)

	if time_remaining_seconds <= 0.0:
		check_win_conditions()


# ==========================================
# JANITOR TEST - J KEY
# ==========================================

func _input(event: InputEvent) -> void:

	if not enable_janitor_test:
		return

	if is_game_over or not day_active:
		return

	if event is InputEventKey:

		if event.pressed and not event.echo:

			if event.keycode == KEY_J:

				print("OFFICE: J pressed")
				test_janitor()


func test_janitor() -> void:

	if not is_instance_valid(janitor_controller):
		push_error("OFFICE: Janitor controller missing.")
		return

	if janitor_controller.state != JanitorController.State.IDLE:
		print("OFFICE: Janitor is already busy.")
		return

	if not is_instance_valid(janitor_controller.bubble):
		push_error("OFFICE: Janitor bubble is not connected.")
		return

	print("OFFICE: Starting manual Janitor test.")

	# Keep the existing hardcoded test proposal.
	# Automatic visits use real dialogue.json ideas.
	janitor_controller.start_visit(
		"Make product line better",
		{
			"Moral": 0,
			"Money": 20000
		}
	)


# ==========================================
# FEEDBACK AUDIO
# ==========================================

func play_feedback_audio(changes: Dictionary) -> void:

	var money_change: int = int(changes.get("Money", 0))
	var moral_change: int = int(changes.get("Moral", 0))

	if money_change > 0:

		if sfx_money_positive:
			sfx_money_positive.play()

	elif money_change < 0:

		if sfx_money_negative:
			sfx_money_negative.play()

	if moral_change > 0:

		if sfx_morale_positive:
			sfx_morale_positive.play()

	elif moral_change < 0:

		if sfx_morale_negative:
			sfx_morale_negative.play()


# ==========================================
# CHANGE MONEY AND MORALE
# ==========================================

func modify_game_stats(changes: Dictionary) -> void:

	if is_game_over or not day_active:
		return

	current_money += int(changes.get("Money", 0))
	company_happiness += int(changes.get("Moral", 0))

	company_happiness = clampi(
		company_happiness,
		0,
		100
	)

	update_ui()

	if company_happiness <= 0:

		trigger_loss(
			"Your coworkers had enough. Company morale reached 0%!"
		)


# ==========================================
# UPDATE UI
# ==========================================

func update_ui() -> void:

	if global_morale_ui:

		global_morale_ui.update_morale_display(
			company_happiness,
			current_money,
			money_quota
		)


# ==========================================
# STOP DAILY ACTIVITY
# ==========================================

func stop_day_activity() -> void:

	day_active = false

	if is_instance_valid(janitor_character):
		janitor_character.stop_janitor_day()

	if is_instance_valid(janitor_controller):
		janitor_controller.cancel_visit()


# ==========================================
# CHECK WIN CONDITIONS
# ==========================================

func check_win_conditions() -> void:

	if is_game_over:
		return

	is_game_over = true
	stop_day_activity()

	if current_money >= money_quota:

		print("OFFICE: Day completed.")

		if game_ui:
			game_ui.show_day_win(
				current_money,
				money_quota
			)

	else:

		if game_ui:
			game_ui.show_game_over()

		print(
			"OFFICE: Day failed. Money: ",
			current_money,
			" / ",
			money_quota
		)


# ==========================================
# START NEXT DAY
# ==========================================

func start_next_day() -> void:

	# Stop any unfinished Janitor activity.
	stop_day_activity()

	is_game_over = true

	current_day += 1

	current_money = 0
	company_happiness = 100

	time_remaining_seconds = total_day_seconds

	money_quota = int(money_quota * 1.4)

	update_ui()

	if game_ui:
		await game_ui.trigger_loading_screen(
			current_day,
			loading_screen_duration
		)

	is_game_over = false
	day_active = true

	# Restart only the special Janitor schedule.
	# Normal NPC dialogue loops are already running.
	if is_instance_valid(janitor_character):

		if is_instance_valid(janitor_controller):

			janitor_character.start_janitor_day()

	print(
		"--- STARTAR DAG %d (Ny kvot: $%d) ---"
		% [current_day, money_quota]
	)


# ==========================================
# GAME OVER
# ==========================================

func trigger_loss(_reason: String) -> void:

	if is_game_over:
		return

	is_game_over = true
	stop_day_activity()

	print("OFFICE: Game over. ", _reason)

	if game_ui:
		game_ui.show_game_over()
