extends Node
# Manages locations, exploration, and available actions

# Current location and findings
var current_location: String = "res://images/locations/static.png"
var found_resource: String = ""
var available_actions: Array = ["redeploy", "explore"]

# Images for the camera
var location_images = {
	"static": "res://images/locations/static.png",
	"nothing": [
		"res://images/locations/nothing1.png", 
		"res://images/locations/nothing2.png", 
		"res://images/locations/nothing3.png"
	],
	"building": [
		"res://images/locations/building1.png", 
		"res://images/locations/building2.png", 
		"res://images/locations/building3.png"
	],
	"wreckage": [
		"res://images/locations/wreck1.png", 
		"res://images/locations/wreck2.png", 
		"res://images/locations/wreck3.png"
	]
}

func _ready():
	# Make sure we start with the static screen
	current_location = location_images.static

# Reset location to default
func reset_location() -> void:
	# Make sure we explicitly set to the static image string, not the dictionary key
	current_location = location_images["static"]
	found_resource = ""
	available_actions = ["redeploy", "explore"]

# Pick a random image from a category
func get_random_location_image(category: String) -> String:
	if category in location_images and location_images[category] is Array:
		return location_images[category][randi() % location_images[category].size()]
	return location_images.static

# Add an action to available actions
func add_available_action(action: String) -> void:
	if not action in available_actions:
		available_actions.append(action)

# Remove an action from available actions
func remove_available_action(action: String) -> void:
	available_actions.erase(action)

# Reset found resource
func reset_found_resource() -> void:
	found_resource = ""
	remove_available_action("transport")

# Exploration action
func explore() -> Dictionary:
	# Reset available actions except for redeploy and explore
	available_actions = ["redeploy", "explore"]
	
	var outcome = randi() % 3
	var result = {}
	
	if outcome == 0:
		result = {
			"message": "You found nothing. Try exploring again.",
			"location_type": "nothing"
		}
		current_location = get_random_location_image("nothing")
	elif outcome == 1:
		result = {
			"message": "You found an abandoned building! You can search it.",
			"location_type": "building"
		}
		current_location = get_random_location_image("building")
		add_available_action("search")
	elif outcome == 2:
		result = {
			"message": "You found a destroyed drone! You can scan it.",
			"location_type": "wreckage"
		}
		current_location = get_random_location_image("wreckage")
		add_available_action("scan")
	
	return result

# Search action
func search() -> Dictionary:
	remove_available_action("search")
	
	var outcome = randi() % 2
	var result = {}
	
	if outcome == 0:
		result = {
			"message": "The search yielded nothing. Keep exploring!",
			"found_resource": ""
		}
	else:
		var resource_options = ["Scrap Metal", "E-Waste", "Plastics"]
		var resource = resource_options[randi() % resource_options.size()]
		
		result = {
			"message": "The search has turned up a small amount of " + resource + ".\nTransport it back or continue on your way!",
			"found_resource": resource
		}
		
		add_available_action("transport")
	
	return result

# Scan action
func scan() -> Dictionary:
	remove_available_action("scan")
	
	# 50% chance to find nothing
	if randf() < 0.5:
		return {
			"message": "The scan didn't reveal anything useful. Try exploring another area.",
			"tech_discovered": "",
			"can_salvage": true  # Still allow salvage even when scan fails
		}
	
	var tech_options = ["ss_batteries", "pv_panel", "hd_lens", "qt_device", "hf_sensors", "he_laser"]
	var scan_outcome = randi() % tech_options.size()
	var tech_id = tech_options[scan_outcome]
	
	# Check if the technology is already discovered
	var tech_manager = get_parent().get_node("TechnologyManager")
	if tech_manager.is_tech_unlocked(tech_id):
		return {
			"message": "You've already discovered " + tech_manager.get_tech_display_name(tech_id) + "!\nYou can still salvage the wreck for resources.",
			"tech_discovered": "",
			"can_salvage": true
		}
	else:
		var tech_descriptions = {
			"ss_batteries": "Install them to increase max energy!",
			"pv_panel": "Install them to decrease Explore cost!",
			"hd_lens": "Install it to decrease Search cost!",
			"qt_device": "Install it to decrease Transport cost!",
			"hf_sensors": "Install them to decrease Scan cost!",
			"he_laser": "Install them to decrease Salvage cost!"
		}
		
		return {
			"message": tech_descriptions.get(tech_id, ""),
			"tech_discovered": tech_id,
			"can_salvage": false
		}

# Salvage action
func salvage() -> Dictionary:
	remove_available_action("salvage")
	
	var resource_options = ["Scrap Metal", "E-Waste", "Plastics"]
	found_resource = resource_options[randi() % resource_options.size()]
	
	add_available_action("transport")
	
	return {
		"message": "You salvaged a small amount of " + found_resource + ".\nTransport it back or continue on your way!"
	}

# Save/Load
func get_save_data() -> Dictionary:
	return {
		"current_location": current_location,
		"found_resource": found_resource,
		"available_actions": available_actions
	}

func load_from_save_data(data: Dictionary) -> void:
	current_location = data.get("current_location", location_images.static)
	found_resource = data.get("found_resource", "")
	available_actions = data.get("available_actions", ["redeploy", "explore"])
