extends Node
# Manages locations, exploration, and available actions

# Current location and findings
var current_location: String = "res://images/locations/static.png"
var available_actions: Array = ["redeploy", "explore"]
var static_material: ShaderMaterial
var static_strength_tween: Tween
var effect_tween: Tween

# Panning effect variables
var panning_active: bool = false
var panning_offset: Vector2 = Vector2.ZERO
var panning_target: Vector2 = Vector2.ZERO
var panning_speed: float = 0.5  # How quickly it moves to target
var panning_range: float = 0.02  # Maximum % of screen to pan
var panning_timer: Timer

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

# For salvage effect - random points based on location type
var extraction_points = {
	"wreckage": [
		Vector2(0.3, 0.4),
		Vector2(0.7, 0.5),
		Vector2(0.5, 0.65),
		Vector2(0.4, 0.6)
	]
}

func _ready():
	# Initialize the static material
	static_material = ShaderMaterial.new()
	static_material.shader = load("res://shaders/static_effect.gdshader")
	static_material.set_shader_parameter("noise_strength", 0.3)
	static_material.set_shader_parameter("noise_speed", 3.0)
	static_material.set_shader_parameter("pixel_density", 300)
	static_material.set_shader_parameter("original_strength", 0.8)
	static_material.set_shader_parameter("offset", Vector2.ZERO)
	
	# Initialize effect parameters to 0
	static_material.set_shader_parameter("search_effect_active", 0.0)
	static_material.set_shader_parameter("scan_effect_active", 0.0)
	static_material.set_shader_parameter("salvage_effect_active", 0.0)
	
	# Make sure we start with the static screen
	current_location = location_images["static"]
	
	# Set up panning timer
	panning_timer = Timer.new()
	panning_timer.wait_time = 2.0  # Change target every 2 seconds
	panning_timer.one_shot = false
	panning_timer.connect("timeout", Callable(self, "_on_panning_timer_timeout"))
	add_child(panning_timer)
	
	# We'll need a reference to the UI controller to access the image
	await get_tree().process_frame
	var ui_controller = get_parent().get_node("UIController")
	if ui_controller and ui_controller.location_image:
		ui_controller.location_image.material = static_material

func _physics_process(delta: float) -> void:
	if panning_active:
		# Interpolate smoothly toward the target
		panning_offset = panning_offset.lerp(panning_target, panning_speed * delta)
		
		# Apply the offset to the shader
		if static_material:
			static_material.set_shader_parameter("offset", panning_offset)

func _on_panning_timer_timeout() -> void:
	if panning_active:
		# Generate new random target within range
		panning_target = Vector2(
			randf_range(-panning_range, panning_range),
			randf_range(-panning_range, panning_range)
		)

func start_panning() -> void:
	panning_active = true
	panning_offset = Vector2.ZERO
	panning_target = Vector2(
		randf_range(-panning_range, panning_range),
		randf_range(-panning_range, panning_range)
	)
	panning_timer.start()

func stop_panning() -> void:
	panning_active = false
	panning_timer.stop()
	# Reset offset
	panning_offset = Vector2.ZERO
	if static_material:
		static_material.set_shader_parameter("offset", Vector2.ZERO)

func animate_static(start_strength: float = 0.8, end_strength: float = 0.1, duration: float = 1.0) -> void:
	# Kill any existing tween
	if static_strength_tween:
		static_strength_tween.kill()
	
	# Create a new tween
	static_strength_tween = create_tween()
	static_strength_tween.tween_method(
		set_static_strength, 
		start_strength, 
		end_strength, 
		duration
	)

func set_static_strength(strength: float) -> void:
	if static_material:
		static_material.set_shader_parameter("noise_strength", strength)

# Helper function to reset all effect parameters
func reset_all_effects() -> void:
	if static_material:
		static_material.set_shader_parameter("search_effect_active", 0.0)
		static_material.set_shader_parameter("scan_effect_active", 0.0)
		static_material.set_shader_parameter("salvage_effect_active", 0.0)

# NEW METHODS FOR VISUAL EFFECTS

# Search effect - Sweeping highlight
func play_search_effect() -> void:
	# Reset all effects first
	reset_all_effects()
	
	if effect_tween:
		effect_tween.kill()
	
	effect_tween = create_tween()
	
	# Set initial values
	static_material.set_shader_parameter("search_effect_active", 1.0)
	static_material.set_shader_parameter("search_sweep_progress", 0.0)
	static_material.set_shader_parameter("search_sweep_width", 0.1)
	static_material.set_shader_parameter("search_highlight_intensity", 0.7)
	
	# Animate sweep from top to bottom
	effect_tween.tween_method(
		set_search_sweep_progress,
		0.0,
		1.0,
		0.5
	)
	
	# Set effect to inactive at the end
	effect_tween.tween_callback(func(): 
		static_material.set_shader_parameter("search_effect_active", 0.0)
	)

func set_search_sweep_progress(progress: float) -> void:
	if static_material:
		static_material.set_shader_parameter("search_sweep_progress", progress)

# Scan effect - Circular pulse
func play_scan_effect() -> void:
	# Reset all effects first
	reset_all_effects()
	
	if effect_tween:
		effect_tween.kill()
	
	effect_tween = create_tween()
	
	# Set initial values
	static_material.set_shader_parameter("scan_effect_active", 1.0)
	static_material.set_shader_parameter("scan_pulse_progress", 0.0)
	static_material.set_shader_parameter("scan_pulse_width", 0.05)
	static_material.set_shader_parameter("scan_highlight_intensity", 0.7)
	
	# Animate pulse from center outward
	effect_tween.tween_method(
		set_scan_pulse_progress,
		0.0,
		1.0,
		0.5
	)
	
	# Set effect to inactive at the end
	effect_tween.tween_callback(func(): 
		static_material.set_shader_parameter("scan_effect_active", 0.0)
	)

func set_scan_pulse_progress(progress: float) -> void:
	if static_material:
		static_material.set_shader_parameter("scan_pulse_progress", progress)

# Salvage effect - Extraction glow
func play_salvage_effect() -> void:
	# Reset all effects first
	reset_all_effects()
	
	if effect_tween:
		effect_tween.kill()
	
	effect_tween = create_tween()
	
	# Pick a random extraction point based on the current location type
	var extraction_point = Vector2(0.5, 0.5)  # Default to center
	
	# Find the location type from the current_location path
	var location_type = "static"
	for type in location_images:
		if type != "static" and location_images[type] is Array:
			for image_path in location_images[type]:
				if current_location == image_path:
					location_type = type
					break
	
	# Get extraction points for the location type
	if location_type in extraction_points and not extraction_points[location_type].is_empty():
		extraction_point = extraction_points[location_type][randi() % extraction_points[location_type].size()]
	
	# Set initial values
	static_material.set_shader_parameter("salvage_effect_active", 1.0)
	static_material.set_shader_parameter("salvage_center", extraction_point)
	static_material.set_shader_parameter("salvage_radius", 0.15)
	static_material.set_shader_parameter("salvage_glow_intensity", 0.8)
	static_material.set_shader_parameter("salvage_pulse_progress", 0.0)
	
	# Animate the pulse progress
	effect_tween.tween_method(
		set_salvage_pulse_progress,
		0.0,
		1.0,
		0.5
	)
	
	# Set effect to inactive at the end
	effect_tween.tween_callback(func(): 
		static_material.set_shader_parameter("salvage_effect_active", 0.0)
	)

func set_salvage_pulse_progress(progress: float) -> void:
	if static_material:
		static_material.set_shader_parameter("salvage_pulse_progress", progress)

# Reset location to default
func reset_location() -> void:
	# Make sure we explicitly set to the static image string, not the dictionary key
	current_location = location_images["static"]
	available_actions = ["redeploy", "explore"]
	
	# Reset all visual effects
	reset_all_effects()
	
	# Stop panning for static screen
	stop_panning()

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

# Exploration action
func explore() -> Dictionary:
	# Reset available actions except for redeploy and explore
	available_actions = ["redeploy", "explore"]
	
	# Reset all visual effects
	reset_all_effects()
	
	# Animate static first
	animate_static(0.8, 0.1, 0.5)
	
	var outcome = randi() % 3
	var result = {}
	
	if outcome == 0:
		result = {
			"message": "You found nothing. Try exploring again.",
			"location_type": "nothing"
		}
		current_location = get_random_location_image("nothing")
		start_panning()  # Start panning effect
	elif outcome == 1:
		result = {
			"message": "You found an abandoned building! You can search it.",
			"location_type": "building"
		}
		current_location = get_random_location_image("building")
		add_available_action("search")
		start_panning()  # Start panning effect
	elif outcome == 2:
		result = {
			"message": "You found a destroyed drone! You can scan it.",
			"location_type": "wreckage"
		}
		current_location = get_random_location_image("wreckage")
		add_available_action("scan")
		start_panning()  # Start panning effect
	
	return result

# Search action
func search() -> Dictionary:
	remove_available_action("search")
	
	# Play the search effect
	play_search_effect()
	
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
		
		# Get the resource manager to directly add the resource
		var resource_manager = get_parent().get_node("ResourceManager")
		resource_manager.add_resource(resource, 1)
		
		result = {
			"message": "The search has turned up a small amount of " + resource + ". It has been added to your inventory.",
			"found_resource": resource
		}
	
	return result

# Scan action
func scan() -> Dictionary:
	remove_available_action("scan")
	
	# Play the scan effect
	play_scan_effect()
	
	# 50% chance to find nothing
	if randf() < 0.5:
		return {
			"message": "The scan didn't reveal anything useful. You can still salvage the wreck.",
			"tech_discovered": "",
			"can_salvage": true  # Still allow salvage even when scan fails
		}
	
	var tech_options = ["ss_batteries", "pv_panel", "hd_lens", "hf_sensors", "he_laser"]
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
	
	# Play the salvage effect
	play_salvage_effect()
	
	var resource_options = ["Scrap Metal", "E-Waste", "Plastics"]
	var resource = resource_options[randi() % resource_options.size()]
	
	# Get the resource manager to directly add the resource
	var resource_manager = get_parent().get_node("ResourceManager")
	resource_manager.add_resource(resource, 1)
	
	return {
		"message": "You salvaged a small amount of " + resource + ". It has been added to your inventory."
	}

# Save/Load
func get_save_data() -> Dictionary:
	return {
		"current_location": current_location,
		"available_actions": available_actions
	}

func load_from_save_data(data: Dictionary) -> void:
	current_location = data.get("current_location", location_images.static)
	available_actions = data.get("available_actions", ["redeploy", "explore"])
	
	# Start panning if we're loading a real location (not static)
	if current_location != location_images["static"]:
		start_panning()
	else:
		stop_panning()
