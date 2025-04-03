extends Node
# Main controller that coordinates other manager classes and handles game flow

# Child manager nodes
@onready var resource_manager = $ResourceManager
@onready var technology_manager = $TechnologyManager
@onready var location_manager = $LocationManager
@onready var save_manager = $SaveManager
@onready var ui_controller = $UIController

# Animation timer
var energy_fill_timer: Timer
var target_energy: int = 0
var energy_fill_speed: float = 1.5  # seconds to fill

# Game state
var redeploy_count = 0
var first_deployment = true

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize game
	load_game()
	
	# Connect signals
	ui_controller.connect("button_clicked", Callable(self, "_on_button_clicked"))
	ui_controller.connect("tech_button_clicked", Callable(self, "_on_tech_button_clicked"))
	technology_manager.connect("energy_changed", Callable(self, "_on_energy_changed"))
	
	# Make sure location is initialized to static screen
	location_manager.reset_location()
	
	# Set initial deployment state
	if redeploy_count == 0:
		first_deployment = true
		# Only show deploy button on first run
		location_manager.available_actions = ["redeploy"]
	else:
		first_deployment = false
	
	# Set up energy fill timer
	energy_fill_timer = Timer.new()
	energy_fill_timer.wait_time = 0.05  # 50ms updates for smooth animation
	energy_fill_timer.one_shot = false
	energy_fill_timer.connect("timeout", Callable(self, "_on_energy_fill_tick"))
	add_child(energy_fill_timer)
	
	# Initialize UI
	update_all_displays()
	
	# Update redeploy button text for first deployment
	if first_deployment:
		ui_controller.set_redeploy_button_text("DEPLOY DRONE")
	
	# Log game start
	log_result("DRONE system initialized. Ready for deployment.")

# Update all UI elements
func update_all_displays():
	ui_controller.update_energy_display(
		technology_manager.energy, 
		technology_manager.max_energy
	)
	
	ui_controller.update_resource_display(
		resource_manager.get_all_resources()
	)
	
	ui_controller.update_tech_display(
		technology_manager.get_all_tech_data()
	)
	
	ui_controller.update_button_energy_cost(
		technology_manager.get_all_action_costs()
	)
	
	ui_controller.update_camera_display(
		location_manager.current_location
	)
	
	ui_controller.update_action_buttons_visibility(
		location_manager.available_actions
	)

# Update all displays except energy (used during animation)
func update_displays_except_energy():
	ui_controller.update_resource_display(
		resource_manager.get_all_resources()
	)
	
	ui_controller.update_tech_display(
		technology_manager.get_all_tech_data()
	)
	
	ui_controller.update_button_energy_cost(
		technology_manager.get_all_action_costs()
	)
	
	ui_controller.update_camera_display(
		location_manager.current_location
	)
	
	ui_controller.update_action_buttons_visibility(
		location_manager.available_actions
	)

# Handle button clicks from UI
func _on_button_clicked(button_name):
	match button_name:
		"redeploy":
			redeploy()
		"explore":
			explore()
		"search":
			search()
		"scan":
			scan()
		"salvage":
			salvage()
		"save":
			save_game()
		"reset":
			reset_game()
		"clear_log":
			ui_controller.clear_log()

# Handle technology button clicks
func _on_tech_button_clicked(tech_name):
	var costs = technology_manager.get_tech_cost(tech_name)
	if resource_manager.has_enough_resources(costs):
		resource_manager.deduct_resources(costs)
		technology_manager.install_technology(tech_name)
		update_all_displays()
		log_result("Installed " + technology_manager.get_tech_display_name(tech_name) + "!")
	else:
		log_result("Not enough resources.")

# Game actions
func redeploy():
	# First reset the energy to ensure the animation starts from 0
	technology_manager.energy = 0
	
	# Update UI with zero energy
	ui_controller.update_energy_display(technology_manager.energy, technology_manager.max_energy)
	
	# Reset location
	location_manager.reset_location()
	
	# Animate the static effect
	location_manager.animate_static(0.3, 0.8, 0.5)
	
	# Increment deployment counter
	redeploy_count += 1
	
	if first_deployment:
		log_result("Deploying...Drone #" + str(redeploy_count).pad_zeros(6) + " online!")
		first_deployment = false
		ui_controller.set_redeploy_button_text("REDEPLOY")
		# Now that we've deployed, show the explore button
		location_manager.available_actions = ["redeploy", "explore"]
	else:
		log_result("Redeploying...Drone #" + str(redeploy_count).pad_zeros(6) + " online!")
	
	# Update UI except energy (which will be animated)
	update_displays_except_energy()
	
	# Initiate energy refill animation (do this last so UI is updated first)
	technology_manager.refill_energy()

func explore():
	if technology_manager.consume_energy("explore"):
		var result = location_manager.explore()
		log_result(result.message)
		update_all_displays()
	else:
		log_result("Not enough energy.")

func search():
	if technology_manager.consume_energy("search"):
		# Disable action buttons during the effect
		ui_controller.disable_action_buttons()
		
		# Play the search effect and get the result
		var result = location_manager.search()
		
		# Log the result and update UI
		log_result(result.message)
		update_all_displays()
		
		# Re-enable action buttons
		ui_controller.enable_action_buttons()
	else:
		log_result("Not enough energy.")

func scan():
	if technology_manager.consume_energy("scan"):
		# Disable action buttons during the effect
		ui_controller.disable_action_buttons()
		
		# Play the scan effect and get the result
		var result = location_manager.scan()
		
		# Process the scan result
		if result.tech_discovered:
			var tech_id = result.tech_discovered
			var success = technology_manager.unlock_technology(tech_id)
			
			if success:
				log_result("You discovered " + technology_manager.get_tech_display_name(tech_id) + "! " + result.message)
			else:
				log_result("Technology discovery error: " + tech_id)
		else:
			log_result(result.message)
			if result.can_salvage:
				location_manager.add_available_action("salvage")
		
		# Update UI and re-enable buttons
		update_all_displays()
		ui_controller.enable_action_buttons()
	else:
		log_result("Not enough energy.")

func salvage():
	if technology_manager.consume_energy("salvage"):
		# Disable action buttons during the effect
		ui_controller.disable_action_buttons()
		
		# Play the salvage effect and get the result
		var result = location_manager.salvage()
		
		# Log the result and update UI
		log_result(result.message)
		update_all_displays()
		
		# Re-enable action buttons
		ui_controller.enable_action_buttons()
	else:
		log_result("Not enough energy.")

# Save/Load functionality
func save_game():
	var save_data = {
		"redeploy_count": redeploy_count,
		"first_deployment": first_deployment,
		"resource_data": resource_manager.get_save_data(),
		"tech_data": technology_manager.get_save_data(),
		"location_data": location_manager.get_save_data()
	}
	
	save_manager.save_game(save_data)
	log_result("Game Saved!")

func load_game():
	var data = save_manager.load_game()
	if data:
		redeploy_count = data.get("redeploy_count", 0)
		first_deployment = data.get("first_deployment", redeploy_count == 0)
		resource_manager.load_from_save_data(data.get("resource_data", {}))
		technology_manager.load_from_save_data(data.get("tech_data", {}))
		location_manager.load_from_save_data(data.get("location_data", {}))
		log_result("Game Loaded!")
	else:
		log_result("No Save File Found or corrupted save data!")

func reset_game():
	save_manager.delete_save()
	get_tree().reload_current_scene()

# Energy animation handlers
func _on_energy_changed(current_energy: int, max_energy: int):
	# Set target energy and start animation
	target_energy = max_energy
	
	# Store current action buttons to restore during animation
	if current_energy == 0:
		# Save intended final actions
		var intended_actions = location_manager.available_actions.duplicate()
		energy_fill_timer.set_meta("intended_actions", intended_actions)
		
		# Disable action buttons except redeploy during animation
		# We'll enable them all once the animation completes
		ui_controller.disable_action_buttons(["redeploy"])
		
		# Calculate amount to add each tick to complete in energy_fill_speed seconds
		var ticks_needed = energy_fill_speed / energy_fill_timer.wait_time
		energy_fill_timer.set_meta("energy_per_tick", float(max_energy) / ticks_needed)
		
		# Start the timer
		energy_fill_timer.start()

func _on_energy_fill_tick():
	var current_energy = technology_manager.energy
	var energy_per_tick = energy_fill_timer.get_meta("energy_per_tick")
	
	# Calculate new energy value
	var new_energy = min(current_energy + energy_per_tick, target_energy)
	
	# Update the actual energy value
	technology_manager.energy = new_energy
	
	# Update the UI
	ui_controller.update_energy_display(
		technology_manager.energy, 
		technology_manager.max_energy
	)
	
	# Check if we've reached the target
	if new_energy >= target_energy:
		energy_fill_timer.stop()
		
		# Fix final energy to exact max value
		technology_manager.energy = target_energy
		ui_controller.update_energy_display(technology_manager.energy, technology_manager.max_energy)
		
		# Enable all action buttons now that energy is full
		if energy_fill_timer.has_meta("intended_actions"):
			ui_controller.enable_action_buttons()
	
# Logging
func log_result(text):
	ui_controller.log_message(text)
