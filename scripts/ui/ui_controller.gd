extends Node
# Controls and updates all UI elements

# UI Elements
@onready var energy_label = $"%EnergyLabel"
@onready var energy_bar = $"%EnergyBar"
@onready var result_log = $"%ResultLog"
@onready var location_image = $"%LocationPicture"

# Button references
@onready var action_buttons = {
	"redeploy": $"%RedeployButton",
	"explore": $"%ExploreButton",
	"search": $"%SearchButton",
	"scan": $"%ScanButton",
	"salvage": $"%SalvageButton",
	"save": $"%SaveButton",
	"reset": $"%ResetButton",
	"clear_log": $"%ClearLogButton"
}

# Tech buttons - these will be populated dynamically at runtime
var tech_buttons = {}

# Resource labels
@onready var resource_labels = {
	"Scrap Metal": $"%ScrapMetalLabel",
	"E-Waste": $"%EWasteLabel", 
	"Plastics": $"%PlasticsLabel"
}

# Signals
signal button_clicked(button_name)
signal tech_button_clicked(tech_name)

func _ready():
	# Connect all action buttons
	for button_name in action_buttons:
		var button = action_buttons[button_name]
		if button:
			button.connect("pressed", Callable(self, "_on_action_button_pressed").bind(button_name))
	
	# Find and connect tech buttons
	_setup_tech_buttons()

# Set up tech button references and connections
func _setup_tech_buttons():
	tech_buttons = {}
	
	# Clear existing connections first
	for tech_id in tech_buttons:
		if tech_buttons[tech_id] and tech_buttons[tech_id].is_connected("pressed", Callable(self, "_on_tech_button_pressed")):
			tech_buttons[tech_id].disconnect("pressed", Callable(self, "_on_tech_button_pressed"))
	
	# Map of button names to tech_ids
	var button_to_tech_map = {
		"SSBatteriesButton": "ss_batteries",
		"PVPanelButton": "pv_panel",
		"HDLensButton": "hd_lens",
		"HFSensorsButton": "hf_sensors",
		"HELaserButton": "he_laser"
	}
	
	# Find each button directly using unique names
	for button_name in button_to_tech_map:
		var tech_id = button_to_tech_map[button_name]
		var button = get_node_or_null("%" + button_name)
		
		if button:
			tech_buttons[tech_id] = button
			# Connect the button signal if not already connected
			if not button.is_connected("pressed", Callable(self, "_on_tech_button_pressed")):
				button.connect("pressed", Callable(self, "_on_tech_button_pressed").bind(tech_id))
		else:
			push_error("Could not find tech button: " + button_name)

# Button handlers
func _on_action_button_pressed(button_name: String) -> void:
	emit_signal("button_clicked", button_name)

func _on_tech_button_pressed(tech_name: String) -> void:
	emit_signal("tech_button_clicked", tech_name)
	
# Set the text of the redeploy button
func set_redeploy_button_text(text: String) -> void:
	if action_buttons.has("redeploy") and action_buttons.redeploy:
		action_buttons.redeploy.text = text

# Update energy display
func update_energy_display(current_energy: int, max_energy_val: int) -> void:
	if energy_label and energy_bar:
		energy_label.text = "Energy: " + str(current_energy) + "/" + str(max_energy_val)
		energy_bar.value = current_energy
		energy_bar.max_value = max_energy_val

# Update resource display
func update_resource_display(resources: Dictionary) -> void:
	for resource_name in resource_labels:
		if resource_name in resources and resource_labels[resource_name]:
			resource_labels[resource_name].text = resource_name + ": " + str(resources[resource_name])
			resource_labels[resource_name].visible = resources[resource_name] > 0

# Update technology display
func update_tech_display(tech_data: Dictionary) -> void:
	# Make sure tech buttons are set up
	if tech_buttons.is_empty():
		_setup_tech_buttons()
	
	for tech_id in tech_data:
		if tech_id in tech_buttons and tech_buttons[tech_id]:
			var tech = tech_data[tech_id]
			
			# Debug output if a tech is unlocked but button doesn't show
			if tech.unlocked and not tech_buttons[tech_id].visible:
				print("Setting " + tech_id + " button visible, was hidden before")
			
			# Set visibility based on unlocked status
			tech_buttons[tech_id].visible = tech.unlocked
			
			if tech.installed:
				tech_buttons[tech_id].text = tech.display_name + " Installed"
				tech_buttons[tech_id].disabled = true
			else:
				# Format the cost display
				var cost_text = ""
				for resource in tech.costs:
					if cost_text != "":
						cost_text += ", "
					
					# Format resource name for display (e.g. "scrap_metal" → "Scrap Metal")
					var display_resource = resource.capitalize()
					if resource.find("_") >= 0:
						var parts = resource.split("_")
						display_resource = ""
						for part in parts:
							if display_resource != "":
								display_resource += " "
							display_resource += part.capitalize()
					
					cost_text += str(tech.costs[resource]) + " " + display_resource
				
				tech_buttons[tech_id].text = tech.display_name + "\n" + cost_text
				tech_buttons[tech_id].disabled = false

# Update button energy costs
func update_button_energy_cost(costs: Dictionary) -> void:
	if "explore" in costs and action_buttons.explore:
		action_buttons.explore.text = "Explore (" + str(costs.explore) + ")"
	
	if "search" in costs and action_buttons.search:
		action_buttons.search.text = "Search (" + str(costs.search) + ")"
	
	if "scan" in costs and action_buttons.scan:
		action_buttons.scan.text = "Scan (" + str(costs.scan) + ")"
	
	if "salvage" in costs and action_buttons.salvage:
		action_buttons.salvage.text = "Salvage (" + str(costs.salvage) + ")"

# Update camera display
func update_camera_display(location_path: String) -> void:
	if location_image:
		# Make sure the path actually exists before trying to load
		if ResourceLoader.exists(location_path):
			location_image.texture = load(location_path)
		else:
			push_error("Could not load image at path: " + location_path)

# Update button visibility based on available actions
func update_action_buttons_visibility(available_actions: Array) -> void:
	for button_name in action_buttons:
		if action_buttons[button_name] and button_name in ["redeploy", "explore", "search", "scan", "salvage"]:
			action_buttons[button_name].visible = button_name in available_actions
			
# Disable all action buttons except those in the exceptions list
func disable_action_buttons(exceptions: Array = []) -> void:
	for button_name in action_buttons:
		if action_buttons[button_name] and button_name in ["redeploy", "explore", "search", "scan", "salvage"]:
			if action_buttons[button_name].visible and not button_name in exceptions:
				action_buttons[button_name].disabled = true

# Enable all visible action buttons
func enable_action_buttons() -> void:
	for button_name in action_buttons:
		if action_buttons[button_name] and action_buttons[button_name].visible:
			action_buttons[button_name].disabled = false

# Log a message to the result log
func log_message(text: String) -> void:
	if result_log:
		var label = Label.new()
		label.text = text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_log.add_child(label)
		result_log.move_child(label, 0)

# Clear the log
func clear_log() -> void:
	if result_log:
		for child in result_log.get_children():
			child.queue_free()
		
		log_message("Log cleared.")
