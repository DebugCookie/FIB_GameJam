
extends ColorRect
class_name MainMenu


# ==========================================
# BUTTONS AND SLIDER
# ==========================================

@onready var start_button: Button = %StartButton
@onready var credits_button: Button = $CreditsButton
@onready var quit_button: Button = %QuitButton

@onready var volume_slider: HSlider = $VolumeSlider


# ==========================================
# SCENE PATHS
# ==========================================

const GAME_SCENE_PATH = "res://maxTestScene.tscn"
const CREDITS_SCENE_PATH = "res://credits.tscn"


# ==========================================
# AUDIO
# ==========================================

var master_bus_index: int = -1


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:

	get_tree().paused = false

	# Connect existing buttons
	start_button.pressed.connect(_on_start_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(func(): get_tree().quit())

	# Get global Master audio bus
	master_bus_index = AudioServer.get_bus_index("Master")

	if master_bus_index == -1:
		push_error("AUDIO: Master bus not found.")
		return

	# Read current global volume
	var current_volume: float = (
		AudioServer.get_bus_volume_linear(master_bus_index)
	)

	# Initialize slider without triggering the signal
	if AudioServer.is_bus_mute(master_bus_index):
		volume_slider.set_value_no_signal(0.0)
	else:
		volume_slider.set_value_no_signal(
			clampf(current_volume * 100.0, 0.0, 100.0)
		)

	# Connect slider
	volume_slider.value_changed.connect(_on_volume_changed)


# ==========================================
# MASTER VOLUME
# ==========================================

func _on_volume_changed(value: float) -> void:

	if master_bus_index == -1:
		return

	# Mute completely at 0
	if value <= 0.0:
		AudioServer.set_bus_mute(master_bus_index, true)
		return

	# Unmute when volume is increased
	AudioServer.set_bus_mute(master_bus_index, false)

	# Convert 0-100 slider into 0.0-1.0 volume
	var volume_linear: float = value / 100.0

	AudioServer.set_bus_volume_linear(
		master_bus_index,
		volume_linear
	)


# ==========================================
# START GAME
# ==========================================

func _on_start_pressed() -> void:

	get_tree().change_scene_to_file(GAME_SCENE_PATH)


# ==========================================
# CREDITS
# ==========================================

func _on_credits_pressed() -> void:

	get_tree().change_scene_to_file(CREDITS_SCENE_PATH)
