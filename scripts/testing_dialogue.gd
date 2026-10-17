class_name DialogueManager
extends Node

var dialogue_data: Dictionary = {}

func load_dialogue_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return false
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) == OK:
		dialogue_data = json.data
		return true
	return false

# Tar nu bara emot karaktärsnamnet, struntar helt i kategorier
func pop_weighted_item(character_name: String) -> Dictionary:
	# Hämtar listan med dialoger direkt från karaktären
	var items: Array = dialogue_data.get(character_name, [])
	
	if items.is_empty(): 
		return {}
	
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
			items.remove_at(i) # Tar fortfarande bort raden så den inte upprepas
			return selected_item
			
	return {}
