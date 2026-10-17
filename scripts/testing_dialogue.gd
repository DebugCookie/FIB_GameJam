class_name DialogueManager
extends Node

var dialogue_data: Dictionary = {}

func load_dialogue_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		printerr("Hittade inte filen: ", file_path)
		return false
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) == OK:
		dialogue_data = json.data
		return true
	return false

# Hämtar alla tillgängliga karaktärsnamn
func get_character_names() -> Array:
	return dialogue_data.keys()

# Hämtar kategorierna för en specifik karaktär (t.ex. ["pro_employee", "pro_work"])
func get_character_categories(character_name: String) -> Array:
	var char_data = dialogue_data.get(character_name, {})
	return char_data.keys()

# Hämtar rådata-listan för en karaktärs specifika kategori
func get_category_data(character_name: String, category: String) -> Array:
	var char_data = dialogue_data.get(character_name, {})
	return char_data.get(category, [])

# Rullar ett slumpmässigt, viktat objekt baserat på karaktär och kategori
func roll_weighted_item(character_name: String, category: String) -> Dictionary:
	var items = get_category_data(character_name, category)
	
	var total_weight: int = 0
	for item in items:
		total_weight += int(item.get("weight", 0))
		
	if total_weight == 0: return {}
	
	var random_roll = randi() % total_weight
	var current_sum = 0
	for item in items:
		current_sum += int(item.get("weight", 0))
		if random_roll < current_sum:
			return item
	return {}
