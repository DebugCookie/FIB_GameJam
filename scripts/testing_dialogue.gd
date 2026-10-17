class_name DialogueManager
extends Node

var dialogue_data: Dictionary = {}
var backup_dialogue_data: Dictionary = {}

func load_dialogue_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return false
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) == OK:
		dialogue_data = json.data
		backup_dialogue_data = str_to_var(var_to_str(dialogue_data))
		return true
	return false

func pop_weighted_item(character_name: String) -> Dictionary:
	var items: Array = dialogue_data.get(character_name, [])
	
	if items.is_empty(): 
		var fresh_items = backup_dialogue_data.get(character_name, [])
		if fresh_items.is_empty(): 
			return {}
		
		dialogue_data[character_name] = str_to_var(var_to_str(fresh_items))
		items = dialogue_data[character_name]
		print("Dialoger slut för ", character_name, " -> Laddar om listan från start!")
	
	var total_weight: int = 0
	for item in items:
		total_weight += int(item.get("weight", 0))
		
	if total_weight == 0: 
		return {}
	
	var random_roll = randi() % total_weight
	var current_sum = 0
	
	for i in range(items.size()):
		current_sum += int(items[i].get("weight", 0))
		if random_roll < current_sum:
			var selected_item = items[i]
			items.remove_at(i) 
			return selected_item
			
	return {}
