
extends Node3D


# ==========================================
# EXISTING NODE REFERENCES
# ==========================================

@onready var global_morale_ui: GlobalMorale3D = $GlobalMorale3D
@onready var characters_container: Node3D = $Characters
@onready var game_ui: GameUI = $GameUI

@onready var sfx_morale_negative: AudioStreamPlayer3D = $SFX_Morale_Negative
@onready var sfx_morale_positive: AudioStreamPlayer3D = $SFX_Morale_Positive
@onready var sfx_money_positive: AudioStreamPlayer3D = $SFX_Money_Positive
@onready var sfx_money_negative: AudioStreamPlayer3D = $SFX_Money_Negative


# ==========================================
# GAME SETTINGS
# ==========================================

@export_group("Game Settings")

@export var day_duration_minutes: float = 2.0
@export var money_quota: int = 30000
@export var loading_screen_duration: float = 3.0


# ==========================================
# JANITOR SETTINGS
# Assign these in the main office Inspector
# ==========================================

@export_group("Janitor")

@export var janitor_controller: JanitorController

# Character3D instance whose Bubble3D
# will be used by the Janitor.
@export var janitor_dialogue_character: Character3D

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

const DIALOGUE_FILE_PATH = "res://Json/dialogue.json"

var is_game_over: bool = false


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:

	manager = DialogueManager.new()

	if not manager.load_dialogue_file(DIALOGUE_FILE_PATH):
		print("Kunde inte ladda JSON-dialogbanken!")
		return

	total_day_seconds = day_duration_minutes * 60.0
	time_remaining_seconds = total_day_seconds

	if game_ui:
		game_ui.next_day_started.connect(start_next_day)

	# Connect the Janitor to their dialogue bubble
	setup_janitor()

	_start_first_day()


# ==========================================
# JANITOR INITIALIZATION
# ==========================================

func setup_janitor() -> void:

	if not is_instance_valid(janitor_controller):
		push_warning("OFFICE: Janitor controller not assigned.")
		return

	if not is_instance_valid(janitor_dialogue_character):
		push_warning("OFFICE: Janitor dialogue character not assigned.")
		return

	# Find the Bubble3D inside the character scene
	var janitor_bubble: Bubble3D = find_bubble(
		janitor_dialogue_character
	)

	if janitor_bubble == null:
		push_error("OFFICE: No Bubble3D found in Janitor dialogue character.")
		return

	# Connect the bubble to the Janitor controller
	janitor_controller.set_bubble(janitor_bubble)

	# Connect the bubble to existing gameplay systems
	if not janitor_bubble.action_processed.is_connected(modify_game_stats):
		janitor_bubble.action_processed.connect(modify_game_stats)

	if not janitor_bubble.bubble_expired.is_connected(modify_game_stats):
		janitor_bubble.bubble_expired.connect(modify_game_stats)

	if not janitor_bubble.feedback_triggered.is_connected(play_feedback_audio):
		janitor_bubble.feedback_triggered.connect(play_feedback_audio)

	print("OFFICE: Janitor successfully connected.")


# ==========================================
# FIND BUBBLE INSIDE CHARACTER SCENE
# ==========================================

func find_bubble(parent: Node) -> Bubble3D:

	if parent is Bubble3D:
		return parent as Bubble3D

	for child in parent.get_children():

		var result: Bubble3D = find_bubble(child)

		if result != null:
			return result

	return null


# ==========================================
# FIRST DAY
# ==========================================

func _start_first_day() -> void:

	if game_ui:
		await game_ui.trigger_loading_screen(
			current_day,
			loading_screen_duration
		)

	update_ui()

	for character in characters_container.get_children():

		if character is Character3D:

			# Janitor's dialogue character is controlled
			# separately by JanitorController.
			if character == janitor_dialogue_character:
				continue

			character.start_character_loop(manager, self)


# ==========================================
# GAME TIMER
# ==========================================

func _process(delta: float) -> void:

	if is_game_over:
		return

	if time_remaining_seconds > 0:

		time_remaining_seconds -= delta

		if global_morale_ui:
			global_morale_ui.update_time_and_round(
				current_day,
				time_remaining_seconds
			)

	else:

		time_remaining_seconds = 0

		if global_morale_ui:
			global_morale_ui.update_time_and_round(
				current_day,
				0
			)

		check_win_conditions()


# ==========================================
# JANITOR TEST - PRESS J
# ==========================================

func _unhandled_key_input(event: InputEvent) -> void:

	if not enable_janitor_test:
		return

	if is_game_over:
		return

	if event is InputEventKey:

		if event.pressed and not event.echo:

			if event.keycode == KEY_J:

				test_janitor()


func test_janitor() -> void:

	if not is_instance_valid(janitor_controller):
		push_error("OFFICE: Janitor controller missing.")
		return

	if janitor_controller.state != JanitorController.State.IDLE:
		print("OFFICE: Janitor already busy.")
		return

	if not is_instance_valid(janitor_controller.bubble):
		push_error("OFFICE: Janitor bubble not connected.")
		return

	print("OFFICE: Starting Janitor test.")

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

	var money_change = int(changes.get("Money", 0))
	var moral_change = int(changes.get("Moral", 0))

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

	if is_game_over:
		return

	current_money += int(changes.get("Money", 0))
	company_happiness += int(changes.get("Moral", 0))

	company_happiness = clamp(
		company_happiness,
		0,
		100
	)

	update_ui()

	if company_happiness <= 0:
		trigger_loss(
			"Your coworkers had enough. company moral reached 0%!"
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
# CHECK WIN CONDITIONS
# ==========================================

func check_win_conditions() -> void:

	if is_game_over:
		return

	# Prevent repeated win/loss checks
	is_game_over = true

	if current_money >= money_quota:

		print("Dagen avklarad! Öppnar vinstmenyn.")

		if game_ui:
			game_ui.show_day_win(
				current_money,
				money_quota
			)

	else:

		trigger_loss(
			"Times out! You didn't reach $%d. You only earned $%d."
			% [money_quota, current_money]
		)


# ==========================================
# NEXT DAY
# ==========================================

func start_next_day() -> void:

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

	print(
		"--- STARTAR DAG %d (Ny kvot: $%d) ---"
		% [current_day, money_quota]
	)


# ==========================================
# GAME OVER
# ==========================================

func trigger_loss(_reason: String) -> void:

	is_game_over = true

	if game_ui:
		game_ui.show_game_over()
