extends Node3D
class_name Character3D

@export var character_name: String = "Anna"
@export var min_spawn_cooldown: float = 5.0
@export var max_spawn_cooldown: float = 10.0

@onready var bubble_3d: Bubble3D = $Bubble3D

var world_scene: Node = null 
var manager: DialogueManager = null
var is_speaking: bool = false

func start_character_loop(dm_manager: DialogueManager, main_world: Node) -> void:
	manager = dm_manager
	world_scene = main_world
	
	bubble_3d.action_processed.connect(_on_bubble_action_processed)
	bubble_3d.bubble_expired.connect(_on_bubble_ignored)
	
	prepare_next_speech()

func prepare_next_speech() -> void:
	is_speaking = false
	var random_cooldown = randf_range(min_spawn_cooldown, max_spawn_cooldown)
	await get_tree().create_timer(random_cooldown).timeout
	
	trigger_speech()

func trigger_speech() -> void:
	if is_speaking: return
	
	var rolled_dialogue = manager.pop_weighted_item(character_name)
	if rolled_dialogue.is_empty(): return 
		
	var text = rolled_dialogue.get("text", "")
	
	var impact = rolled_dialogue.get("morale_impact", {"employee": 0, "work": 0})
	var converted_impact = {
		"happiness": int(impact.get("employee", 0)),
		"money": int(impact.get("work", 0)) * 10 # Multiplicera för att få pengakänsla
	}
	
	is_speaking = true
	bubble_3d.setup_bubble(character_name, text, converted_impact)


func _on_bubble_action_processed(impact_change: Dictionary) -> void:
	world_scene.modify_game_stats(impact_change)
	prepare_next_speech()

func _on_bubble_ignored(penalty: Dictionary) -> void:
	world_scene.modify_game_stats(penalty)
	prepare_next_speech()
