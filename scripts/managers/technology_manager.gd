extends Node
# Manages all technologies, upgrades, and energy

# Energy variables
var max_energy: int = 100
var energy: int = 0

# Energy costs for each action
var energy_cost_explore: int = 10
var energy_cost_search: int = 10
var energy_cost_scan: int = 10
var energy_cost_salvage: int = 10

# Dictionary to map actions to their cost variables
const ACTION_COST_MAP = {
	"explore": "energy_cost_explore",
	"search": "energy_cost_search",
	"scan": "energy_cost_scan",
	"salvage": "energy_cost_salvage"
}

# Technologies data structure
# Format: technology_id: {unlocked: bool, installed: bool, display_name: String, description: String, costs: {resource: amount}, effect: Callable}
var technologies = {
	"ss_batteries": {
		"unlocked": false,
		"installed": false,
		"display_name": "SS Batteries",
		"description": "Increase maximum energy capacity",
		"costs": {"scrap_metal": 1, "e_waste": 4},
		"effect": func(): max_energy = 200
	},
	"pv_panel": {
		"unlocked": false,
		"installed": false,
		"display_name": "PV Panel",
		"description": "Decreases Explore energy cost",
		"costs": {"e_waste": 2, "plastics": 3},
		"effect": func(): energy_cost_explore = 5
	},
	"hd_lens": {
		"unlocked": false,
		"installed": false,
		"display_name": "HD Lens",
		"description": "Decreases Search energy cost",
		"costs": {"scrap_metal": 1, "plastics": 4},
		"effect": func(): energy_cost_search = 5
	},
	"hf_sensors": {
		"unlocked": false,
		"installed": false,
		"display_name": "HF Sensors",
		"description": "Decreases Scan energy cost",
		"costs": {"scrap_metal": 2, "e_waste": 3},
		"effect": func(): energy_cost_scan = 5
	},
	"he_laser": {
		"unlocked": false,
		"installed": false,
		"display_name": "HE Laser",
		"description": "Decreases Salvage energy cost",
		"costs": {"e_waste": 4, "plastics": 1},
		"effect": func(): energy_cost_salvage = 5
	}
}

# Check technology status
func is_tech_unlocked(tech_id: String) -> bool:
	return technologies.has(tech_id) and technologies[tech_id].unlocked

func is_tech_installed(tech_id: String) -> bool:
	return technologies.has(tech_id) and technologies[tech_id].installed

# Get technology data
func get_tech_display_name(tech_id: String) -> String:
	if technologies.has(tech_id):
		return technologies[tech_id].display_name
	return "Unknown Technology"

func get_tech_cost(tech_id: String) -> Dictionary:
	if technologies.has(tech_id):
		return technologies[tech_id].costs
	return {}

# Get data needed for UI display
func get_all_tech_data() -> Dictionary:
	var result = {}
	for tech_id in technologies:
		result[tech_id] = {
			"unlocked": technologies[tech_id].unlocked,
			"installed": technologies[tech_id].installed,
			"display_name": technologies[tech_id].display_name,
			"description": technologies[tech_id].description,
			"costs": technologies[tech_id].costs
		}
	return result

# Get all action costs for UI
func get_all_action_costs() -> Dictionary:
	return {
		"explore": energy_cost_explore,
		"search": energy_cost_search,
		"scan": energy_cost_scan,
		"salvage": energy_cost_salvage
	}

# Unlock a technology so it can be installed
func unlock_technology(tech_id: String) -> bool:
	if not technologies.has(tech_id):
		return false
	
	technologies[tech_id].unlocked = true
	return true

# Install a technology to get its benefits
func install_technology(tech_id: String) -> bool:
	if not technologies.has(tech_id) or not technologies[tech_id].unlocked or technologies[tech_id].installed:
		return false
	
	technologies[tech_id].installed = true
	
	# Apply the technology's effect
	if "effect" in technologies[tech_id] and technologies[tech_id].effect is Callable:
		technologies[tech_id].effect.call()
	
	return true

# Energy management
func consume_energy(action: String) -> bool:
	if not ACTION_COST_MAP.has(action):
		push_error("Unknown action: " + action)
		return false
	
	var cost_var_name = ACTION_COST_MAP[action]
	var cost = get(cost_var_name)
	
	if energy >= cost:
		energy -= cost
		return true
	
	return false

# Signal for energy changes
signal energy_changed(current, maximum)

# Animates energy filling from current to maximum
func refill_energy() -> void:
	# Start at 0 if we're not already partway filled
	if energy == 0:
		emit_signal("energy_changed", 0, max_energy)
	
	# We'll use a signal to let GameManager handle the animation
	# This way we just inform about the energy change
	emit_signal("energy_changed", energy, max_energy)

# Save/Load
func get_save_data() -> Dictionary:
	var tech_save_data = {}
	for tech_id in technologies:
		tech_save_data[tech_id] = {
			"unlocked": technologies[tech_id].unlocked,
			"installed": technologies[tech_id].installed
		}
	
	return {
		"max_energy": max_energy,
		"energy": energy,
		"energy_costs": {
			"explore": energy_cost_explore,
			"search": energy_cost_search,
			"scan": energy_cost_scan,
			"salvage": energy_cost_salvage
		},
		"technologies": tech_save_data
	}

func load_from_save_data(data: Dictionary) -> void:
	max_energy = data.get("max_energy", 100)
	energy = data.get("energy", max_energy)
	
	var energy_costs = data.get("energy_costs", {})
	energy_cost_explore = energy_costs.get("explore", 10)
	energy_cost_search = energy_costs.get("search", 10)
	energy_cost_scan = energy_costs.get("scan", 10)
	energy_cost_salvage = energy_costs.get("salvage", 10)
	
	var tech_data = data.get("technologies", {})
	for tech_id in tech_data:
		if technologies.has(tech_id):
			technologies[tech_id].unlocked = tech_data[tech_id].get("unlocked", false)
			
			if tech_data[tech_id].get("installed", false):
				technologies[tech_id].installed = true
				# Apply effect for installed technologies
				if "effect" in technologies[tech_id] and technologies[tech_id].effect is Callable:
					technologies[tech_id].effect.call()
