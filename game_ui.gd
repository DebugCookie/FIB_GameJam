extends CanvasLayer
class_name GameUI

@onready var pause_menu: PauseMenu = $PauseMenu
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var loading_screen: ColorRect = $LoadingScreen
@onready var day_indicator_label: Label = $LoadingScreen/VBoxContainer/DayIndicatorLabel

# Ändra till den exakta sökvägen till din fristående huvudmenyscen
const MAIN_MENU_SCENE_PATH = "res://main_menu.tscn"

func _ready() -> void:
	# Startläge inuti 3D-världen: Allt 2D UI är dolt, spelet är igång
	pause_menu.hide()
	game_over_screen.hide()
	loading_screen.hide()
	get_tree().paused = false
	
	# Koppla signaler
	pause_menu.resume_requested.connect(_on_resume_game)
	pause_menu.main_menu_requested.connect(_on_go_to_main_menu)
	game_over_screen.restart_requested.connect(_on_restart_game)

func _input(event: InputEvent) -> void:
	# Öppna/stäng pausmenyn med Escape
	if event.is_action_pressed("ui_cancel") and not game_over_screen.visible and not loading_screen.visible:
		if get_tree().paused and pause_menu.visible:
			_on_resume_game()
		else:
			show_pause()

func show_pause() -> void:
	pause_menu.show()
	get_tree().paused = true

func _on_resume_game() -> void:
	pause_menu.hide()
	get_tree().paused = false

func _on_go_to_main_menu() -> void:
	# Unpausa och hoppa tillbaka till Scen 1 (Huvudmenyn)
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func show_game_over() -> void:
	game_over_screen.show()
	get_tree().paused = true

func _on_restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene() # Startar om 3D-världen direkt

func trigger_loading_screen(day_number: int, duration: float) -> void:
	get_tree().paused = true
	day_indicator_label.text = "FÖRBEREDER DAG %d...\nGör dig redo!" % day_number
	loading_screen.show()
	
	await get_tree().create_timer(duration, true, false, true).timeout
	
	loading_screen.hide()
	get_tree().paused = false
