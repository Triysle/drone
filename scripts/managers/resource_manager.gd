extends Node
# Manages all resources in the game

# Resource quantities
var scrap_metal: int = 0
var e_waste: int = 0
var plastics: int = 0

# Resource definitions for easy access
const RESOURCE_TYPES = {
	"Scrap Metal": "scrap_metal",
	"E-Waste": "e_waste",
	"Plastics": "plastics"
}

# Get a dictionary of all resources and their quantities
func get_all_resources() -> Dictionary:
	return {
		"Scrap Metal": scrap_metal,
		"E-Waste": e_waste,
		"Plastics": plastics
	}

# Add a specific resource
func add_resource(resource_name: String, amount: int = 1) -> void:
	match resource_name:
		"Scrap Metal":
			scrap_metal += amount
		"E-Waste":
			e_waste += amount
		"Plastics":
			plastics += amount
		_:
			push_error("Unknown resource: " + resource_name)

# Check if player has enough resources for a cost
func has_enough_resources(cost_dict: Dictionary) -> bool:
	if "scrap_metal" in cost_dict and scrap_metal < cost_dict["scrap_metal"]:
		return false
	if "e_waste" in cost_dict and e_waste < cost_dict["e_waste"]:
		return false
	if "plastics" in cost_dict and plastics < cost_dict["plastics"]:
		return false
	return true

# Deduct resources based on a cost dictionary
func deduct_resources(cost_dict: Dictionary) -> void:
	if "scrap_metal" in cost_dict:
		scrap_metal -= cost_dict["scrap_metal"]
	if "e_waste" in cost_dict:
		e_waste -= cost_dict["e_waste"]
	if "plastics" in cost_dict:
		plastics -= cost_dict["plastics"]

# Reset all resources
func reset_resources() -> void:
	scrap_metal = 0
	e_waste = 0
	plastics = 0

# Get save data
func get_save_data() -> Dictionary:
	return {
		"scrap_metal": scrap_metal,
		"e_waste": e_waste,
		"plastics": plastics
	}

# Load from save data
func load_from_save_data(data: Dictionary) -> void:
	scrap_metal = data.get("scrap_metal", 0)
	e_waste = data.get("e_waste", 0)
	plastics = data.get("plastics", 0)
