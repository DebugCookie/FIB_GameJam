
extends Node3D
class_name Character3D


# ==========================================
# GENERAL CHARACTER SETTINGS
# ==========================================

@export var character_name: String = "Anna"
@export var min_spawn_cooldown: float = 5.0
@export var max_spawn_cooldown: float = 10.0

@export var custom_sfx_node: AudioStreamPlayer3D

@onready var bubble_3d: Bubble3D = $Bubble3D


# ==========================================
# JANITOR SETTINGS
# ==========================================

@export_group("Janitor")

@export var is_janitor: bool = false
@export var janitor_controller: JanitorController

# Seconds after the working day starts.
@export var janitor_first_min: float = 60.0
@export var janitor_first_max: float = 75.0

# Pause starts when Janitor returns to Point A.
@export var janitor_min_pause: float = 30.0
@export var janitor_max_pause: float = 35.0

@export_range(1, 2, 1) var janitor_max_visits: int = 2


# ==========================================
# GENERAL VARIABLES
# ==========================================

var world_scene: Node = null
var manager: DialogueManager = null
var is_speaking: bool = false


# ==========================================
# JANITOR VARIABLES
# ==========================================

var janitor_visits: int = 0
var janitor_target_visits: int = 1

var janitor_schedule_running: bool = false
var janitor_auto_visit_in_progress: bool = false

var janitor_next_visit_at: float = -1.0


# ==========================================
# INITIALIZATION
# ==========================================

func start_character_loop(
	dm_manager: DialogueManager,
	main_world: Node
) -> void:

	manager = dm_manager
	world_scene = main_world

	# Connect dialogue events only once.
	if not bubble_3d.action_processed.is_connected(
		_on_bubble_action_processed
	):
		bubble_3d.action_processed.connect(
			_on_bubble_action_processed
		)

	if not bubble_3d.bubble_expired.is_connected(
		_on_bubble_ignored
	):
		bubble_3d.bubble_expired.connect(
			_on_bubble_ignored
		)

	if not bubble_3d.feedback_triggered.is_connected(
		_on_feedback_triggered
	):
		bubble_3d.feedback_triggered.connect(
			_on_feedback_triggered
		)

	# Special Janitor setup.
	if is_janitor:

		if not is_instance_valid(janitor_controller):
			push_error("JANITOR: Controller not assigned.")
			return

		# Connect this character's own Bubble3D.
		janitor_controller.set_bubble(bubble_3d)

		# Listen for the full exit sequence finishing.
		if not janitor_controller.visit_finished.is_connected(
			_on_janitor_visit_finished
		):
			janitor_controller.visit_finished.connect(
				_on_janitor_visit_finished
			)

		print("JANITOR: Character initialized.")
		print("JANITOR: Character name = ", character_name)

		start_janitor_day()
		return

	# Ordinary NPC behavior.
	prepare_next_speech()


# ==========================================
# FEEDBACK AUDIO
# ==========================================

func _on_feedback_triggered(impact: Dictionary) -> void:

	if is_instance_valid(world_scene):
		world_scene.play_feedback_audio(impact)


# ==========================================
# NORMAL NPC DIALOGUE
# ==========================================

func prepare_next_speech() -> void:

	if is_janitor:
		return

	is_speaking = false

	var random_cooldown: float = randf_range(
		minf(min_spawn_cooldown, max_spawn_cooldown),
		maxf(min_spawn_cooldown, max_spawn_cooldown)
	)

	await get_tree().create_timer(
		random_cooldown,
		false
	).timeout

	trigger_speech()


func trigger_speech() -> void:

	if is_janitor:
		return

	if is_speaking:
		return

	if manager == null:
		return

	var rolled_dialogue: Dictionary = manager.pop_weighted_item(
		character_name
	)

	if rolled_dialogue.is_empty():
		prepare_next_speech()
		return

	var text: String = str(
		rolled_dialogue.get("text", "")
	)

	var impact: Dictionary = rolled_dialogue.get(
		"morale_impact",
		{"Moral": 0, "Money": 0}
	)

	if custom_sfx_node and custom_sfx_node.stream:
		custom_sfx_node.play()

	is_speaking = true

	bubble_3d.setup_bubble(
		character_name,
		text,
		impact
	)


func _on_bubble_action_processed(
	impact_change: Dictionary
) -> void:

	if custom_sfx_node:
		custom_sfx_node.stop()

	if is_instance_valid(world_scene):
		world_scene.modify_game_stats(impact_change)

	if not is_janitor:
		prepare_next_speech()


func _on_bubble_ignored(penalty: Dictionary) -> void:

	if custom_sfx_node:
		custom_sfx_node.stop()

	if is_instance_valid(world_scene):
		world_scene.modify_game_stats(penalty)

	if not is_janitor:
		prepare_next_speech()


# ==========================================
# JANITOR DAILY SCHEDULING
# ==========================================

func start_janitor_day() -> void:

	if not is_janitor:
		return

	if manager == null:
		push_error("JANITOR: DialogueManager missing.")
		return

	if not is_instance_valid(world_scene):
		push_error("JANITOR: Office reference missing.")
		return

	janitor_visits = 0

	# Randomly choose 1 or 2 automatic visits.
	janitor_target_visits = randi_range(
		1,
		mini(maxi(janitor_max_visits, 1), 2)
	)

	janitor_auto_visit_in_progress = false
	janitor_schedule_running = true

	# Random first appearance.
	janitor_next_visit_at = randf_range(
		maxf(0.0, minf(janitor_first_min, janitor_first_max)),
		maxf(0.0, maxf(janitor_first_min, janitor_first_max))
	)

	print(
		"JANITOR: Day started. Planned visits: ",
		janitor_target_visits
	)

	print(
		"JANITOR: First visit scheduled at ",
		snappedf(janitor_next_visit_at, 0.1),
		" seconds."
	)


# ==========================================
# JANITOR SCHEDULER UPDATE
# ==========================================

func _process(_delta: float) -> void:

	if not is_janitor:
		return

	update_janitor_schedule()


func update_janitor_schedule() -> void:

	if not janitor_schedule_running:
		return

	if not is_instance_valid(world_scene):
		return

	if not bool(world_scene.get("day_active")):
		return

	if bool(world_scene.get("is_game_over")):
		return

	if janitor_visits >= janitor_target_visits:
		return

	if janitor_next_visit_at < 0.0:
		return

	if not is_instance_valid(janitor_controller):
		return

	var elapsed: float = get_day_elapsed_seconds()

	if elapsed < janitor_next_visit_at:
		return

	# Never interrupt an active Janitor visit.
	if janitor_controller.state != JanitorController.State.IDLE:
		return

	start_automatic_janitor_visit()


# ==========================================
# GET ELAPSED WORKDAY TIME
# ==========================================

func get_day_elapsed_seconds() -> float:

	if not is_instance_valid(world_scene):
		return 0.0

	var total: float = float(
		world_scene.get("total_day_seconds")
	)

	var remaining: float = float(
		world_scene.get("time_remaining_seconds")
	)

	return maxf(total - remaining, 0.0)


# ==========================================
# START AUTOMATIC JANITOR VISIT
# ==========================================

func start_automatic_janitor_visit() -> void:

	if manager == null:
		return

	if not is_instance_valid(janitor_controller):
		return

	if janitor_controller.state != JanitorController.State.IDLE:
		return

	var rolled_dialogue: Dictionary = manager.pop_weighted_item(
		character_name
	)

	if rolled_dialogue.is_empty():

		push_warning(
			"JANITOR: No dialogue found for character name: ",
			character_name
		)

		# Avoid trying to load missing dialogue every frame.
		janitor_schedule_running = false
		return

	var idea_text: String = str(
		rolled_dialogue.get("text", "")
	)

	var impact: Dictionary = rolled_dialogue.get(
		"morale_impact",
		{"Moral": 0, "Money": 0}
	)

	janitor_visits += 1
	janitor_auto_visit_in_progress = true

	# Do not start another visit until this one finishes.
	janitor_next_visit_at = -1.0

	print(
		"JANITOR: Automatic visit ",
		janitor_visits,
		" / ",
		janitor_target_visits
	)

	print("JANITOR: Idea = ", idea_text)

	if custom_sfx_node and custom_sfx_node.stream:
		custom_sfx_node.play()

	janitor_controller.start_visit(
		idea_text,
		impact
	)

	# If the controller rejected the visit because
	# a required node is missing, stop the scheduler.
	if janitor_controller.state == JanitorController.State.IDLE:

		janitor_auto_visit_in_progress = false
		janitor_schedule_running = false

		push_error(
			"JANITOR: Visit failed to start. Check controller Output."
		)


# ==========================================
# JANITOR RETURNED TO POINT A
# ==========================================

func _on_janitor_visit_finished() -> void:

	if not is_janitor:
		return

	if custom_sfx_node:
		custom_sfx_node.stop()

	if not janitor_schedule_running:
		return

	var elapsed: float = get_day_elapsed_seconds()

	# J-key visits do not count toward the daily
	# automatic visit limit.
	if not janitor_auto_visit_in_progress:

		# Still keep a gap after a manual visit.
		janitor_next_visit_at = maxf(
			janitor_next_visit_at,
			elapsed + maxf(janitor_min_pause, 30.0)
		)

		print("JANITOR: Manual visit finished.")
		return

	janitor_auto_visit_in_progress = false

	# End scheduling after the planned number of visits.
	if janitor_visits >= janitor_target_visits:

		janitor_schedule_running = false

		print("JANITOR: Daily visits complete.")
		return

	# Random interval, never less than 30 seconds.
	var min_pause: float = maxf(
		janitor_min_pause,
		30.0
	)

	var max_pause: float = maxf(
		janitor_max_pause,
		min_pause
	)

	var pause: float = randf_range(
		min_pause,
		max_pause
	)

	janitor_next_visit_at = elapsed + pause

	print(
		"JANITOR: Next visit scheduled at ",
		snappedf(janitor_next_visit_at, 0.1),
		" seconds."
	)


# ==========================================
# STOP JANITOR DAY
# ==========================================

func stop_janitor_day() -> void:

	if not is_janitor:
		return

	janitor_schedule_running = false
	janitor_auto_visit_in_progress = false
	janitor_next_visit_at = -1.0

	if custom_sfx_node:
		custom_sfx_node.stop()

	print("JANITOR: Daily schedule stopped.")
