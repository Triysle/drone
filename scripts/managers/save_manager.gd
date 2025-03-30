extends Node
# Handles saving and loading game data

const SAVE_PATH = "user://savegame.json"

# Save the game with provided data
func save_game(save_data: Dictionary) -> bool:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		return true
	
	push_error("Failed to open save file for writing")
	return false

# Load game data from save file
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open save file for reading")
		return {}
	
	var json_string = file.get_as_text()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse save file JSON: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Unexpected save data format")
		return {}
	
	return data

# Delete the save file
func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var result = DirAccess.remove_absolute(SAVE_PATH)
		if result != OK:
			push_error("Failed to delete save file")
			return false
		return true
	return false
