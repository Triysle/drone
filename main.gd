extends Node

# Prep all UI elements
@onready var energy_label = $UI/EnergyBar/EnergyLabel
@onready var energy_bar = $UI/EnergyBar
@onready var result_panel = $UI/ResultPanel
@onready var result_log = $UI/ResultPanel/ScrollContainer/ResultLog
@onready var redeploy_button = $UI/ActionButtons/RedeployButton
@onready var explore_button = $UI/ActionButtons/ExploreButton
@onready var search_button = $UI/ActionButtons/SearchButton
@onready var scan_button = $UI/ActionButtons/ScanButton
@onready var salvage_button = $UI/ActionButtons/SalvageButton
@onready var transport_button = $UI/ActionButtons/TransportButton
@onready var save_button = $UI/SystemButtons/SaveButton
@onready var reset_button = $UI/SystemButtons/ResetButton
@onready var resources_list = $UI/ResourcesPanel/ResourcesContainer
@onready var technology_list = $UI/TechPanel/TechContainer
@onready var ss_batteries_button = $UI/TechPanel/TechContainer/SSBatteriesButton
@onready var pv_panel_button = $UI/TechPanel/TechContainer/PVPanelButton
@onready var hd_lens_button = $UI/TechPanel/TechContainer/HDLensButton
@onready var qt_device_button = $UI/TechPanel/TechContainer/QTDeviceButton
@onready var hf_sensors_button = $UI/TechPanel/TechContainer/HFSensorsButton
@onready var he_laser_button = $UI/TechPanel/TechContainer/HELaserButton

var save_path = "user://savegame.json"

# Energy variables
var max_energy = 100
var energy = max_energy

# Resource variables
var scrap_metal = 0
var e_waste = 0
var plastics = 0
var found_resource = ""

# Technology variables
var ss_batteries_unlocked = false
var ss_batteries_installed = false
var pv_panel_unlocked = false
var pv_panel_installed = false
var hd_lens_unlocked = false
var hd_lens_installed = false
var qt_device_unlocked = false
var qt_device_installed = false
var hf_sensors_unlocked = false
var hf_sensors_installed = false
var he_laser_unlocked = false
var he_laser_installed = false

# Energy costs for each action
var energy_cost_explore: int = 10
var energy_cost_search: int = 10
var energy_cost_scan: int = 10
var energy_cost_salvage: int = 10
var energy_cost_transport: int = 10

# Redeploy counter
var redeploy_count = 0

func _ready():
	load_game()

	# Update displays
	update_energy_display()
	update_resource_display()
	update_tech_display()
	update_button_energy_cost()

	redeploy_button.visible = true
	explore_button.visible = true
	
# Update button text with energy cost
func update_button_energy_cost():
	explore_button.text = "Explore (" + str(energy_cost_explore) + ")"
	search_button.text = "Search (" + str(energy_cost_search) + ")"
	salvage_button.text = "Salvage (" + str(energy_cost_salvage) + ")"
	transport_button.text = "Transport (" + str(energy_cost_transport) + ")"
	scan_button.text = "Scan (" + str(energy_cost_scan) + ")"

# Update energy number and progress bar
func update_energy_display():
	energy_label.text = "Energy: " + str(energy) + "/" + str(max_energy)
	energy_bar.value = energy
	energy_bar.max_value = max_energy

# Display resource quantities dynamically
func update_resource_display():

	# Show the labels for discovered resources and update their quantities
	if scrap_metal == 0:
		var scrap_metal_label = resources_list.get_node("ScrapMetalLabel")
		scrap_metal_label.visible = false
		scrap_metal_label.text = "Scrap Metal: " + str(scrap_metal)
		
	if scrap_metal > 0:
		var scrap_metal_label = resources_list.get_node("ScrapMetalLabel")
		scrap_metal_label.visible = true
		scrap_metal_label.text = "Scrap Metal: " + str(scrap_metal)

	if e_waste == 0:
		var e_waste_label = resources_list.get_node("EWasteLabel")
		e_waste_label.visible = false
		e_waste_label.text = "E-Waste: " + str(e_waste)

	if e_waste > 0:
		var e_waste_label = resources_list.get_node("EWasteLabel")
		e_waste_label.visible = true
		e_waste_label.text = "E-Waste: " + str(e_waste)

	if plastics == 0:
		var plastics_label = resources_list.get_node("PlasticsLabel")
		plastics_label.visible = false
		plastics_label.text = "Plastics: " + str(plastics)

	if plastics > 0:
		var plastics_label = resources_list.get_node("PlasticsLabel")
		plastics_label.visible = true
		plastics_label.text = "Plastics: " + str(plastics)

# Update technologies based on unlocked/installed
func update_tech_display():
	
	if ss_batteries_unlocked:
		ss_batteries_button.visible = true
		if ss_batteries_installed:
			ss_batteries_button.text = "SS Batteries Installed"
			ss_batteries_button.disabled = true
	
	if pv_panel_unlocked:
		pv_panel_button.visible = true
		if pv_panel_installed:
			pv_panel_button.text = "PV Panel Installed"
			pv_panel_button.disabled = true
		
	if hd_lens_unlocked:
		hd_lens_button.visible = true
		if hd_lens_installed:
			hd_lens_button.text = "HD Lens Installed"
			hd_lens_button.disabled = true
		
	if qt_device_unlocked:
		qt_device_button.visible = true
		if qt_device_installed:
			qt_device_button.text = "QT Device Installed"
			qt_device_button.disabled = true
	
	if hf_sensors_unlocked:
		hf_sensors_button.visible = true
		if hf_sensors_installed:
			hf_sensors_button.text = "HF Sensors Installed"
			hf_sensors_button.disabled = true
			
	if he_laser_unlocked:
		he_laser_button.visible = true
		if he_laser_installed:
			he_laser_button.text = "HE Laser Installed"
			he_laser_button.disabled = true

func explore():
	if energy >= energy_cost_explore:
		energy -= energy_cost_explore
		update_energy_display()
		
		search_button.visible = false
		salvage_button.visible = false
		transport_button.visible = false
		scan_button.visible = false
		
		var outcome = randi() % 3

		if outcome == 0:
			log_result("You found nothing. Try exploring again.")
		elif outcome == 1:
			log_result("You found an abandoned building! You can search it.")
			search_button.visible = true
		elif outcome == 2:
			log_result("You found a destroyed drone! You can scan it.")
			scan_button.visible = true
	else:
		log_result("Not enough energy.")

func search():
	if energy >= energy_cost_search:
		energy -= energy_cost_search
		update_energy_display()
		search_button.visible = false

		var outcome = randi() % 2
		
		if outcome == 0:
			log_result("The search yielded nothing. Keep exploring!")
		else:
			var resource_options = ["Scrap Metal", "E-Waste", "Plastics"]
			found_resource = resource_options[randi() % resource_options.size()]
			log_result("The search has turned up a small amount of " + found_resource + ".\nTransport it back or continue on your way!")
			transport_button.visible = true
	else:
		log_result("Not enough energy.")

func transport():
	if energy >= energy_cost_transport:
		energy -= energy_cost_transport
		update_energy_display()
		transport_button.visible = false

		# Add the resource to the player's inventory
		if found_resource == "Scrap Metal":
			scrap_metal += 1
		elif found_resource == "E-Waste":
			e_waste += 1
		elif found_resource == "Plastics":
			plastics += 1
		
		log_result("Transported " + found_resource + " back to base...")
		update_resource_display()
	else:
		log_result("Not enough energy.")

func scan():
	if energy >= energy_cost_search:
		energy -= energy_cost_search
		update_energy_display()
		scan_button.visible = false

		var scan_outcome = randi() % 6
		
		if scan_outcome == 0:
			if not ss_batteries_unlocked:
				ss_batteries_button.visible = true
				ss_batteries_unlocked = true
				log_result("You discovered Solid-state Batteries! \nInstall them to increase max energy!")
			else:
				log_result("You've already discovered SS Batteries!")
				log_result("You can still salvage the wreck for resources")
				salvage_button.visible = true
		elif scan_outcome == 1:
			if not pv_panel_unlocked:
				pv_panel_button.visible = true
				pv_panel_unlocked = true
				log_result("You discovered Photovoltaic Panels! Install them to decrease Explore cost!")
			else:
				log_result("You've already discovered PV Panels!")
				log_result("You can still salvage the wreck for resources")
				salvage_button.visible = true
		elif scan_outcome == 2:
			if not hd_lens_unlocked:
				hd_lens_button.visible = true
				hd_lens_unlocked = true
				log_result("You discovered a High Definition Lens! Install it to decrease Search cost!")
			else:
				log_result("You've already discovered HD Lens!")
				log_result("You can still salvage the wreck for resources")
				salvage_button.visible = true
		elif scan_outcome == 3:
			if not qt_device_unlocked:
				qt_device_button.visible = true
				qt_device_unlocked = true
				log_result("You discovered a Quantum Tunneling Device! Install it to decrease Transport cost!")
			else:
				log_result("You've already discovered QT Device!")
				log_result("You can still salvage the wreck for resources")
				salvage_button.visible = true
		elif scan_outcome == 4:
			if not hf_sensors_unlocked:
				hf_sensors_button.visible = true
				hf_sensors_unlocked = true
				log_result("You discovered High-Frequency Sensors! Install them to decrease Scan cost!")
			else:
				log_result("You've already discovered HF Sensors!")
				log_result("You can still salvage the wreck for resources")
				salvage_button.visible = true
		elif scan_outcome == 5:
			if not he_laser_unlocked:
				he_laser_button.visible = true
				he_laser_unlocked = true
				log_result("You discovered High Efficiency Lasers! Install them to decrease Salvage cost!")
			else:
				log_result("You've already discovered HE Lasers!")
				log_result("You can still salvage the wreck for resources")
				salvage_button.visible = true
		
	else:
		log_result("Not enough energy.")

func salvage():
	if energy >= energy_cost_salvage:
		energy -= energy_cost_salvage
		update_energy_display()
		salvage_button.visible = false
		
		var resource_options = ["Scrap Metal", "E-Waste", "Plastics"]
		found_resource = resource_options[randi() % resource_options.size()]
		log_result("You salvaged a small amount of " + found_resource + ".\nTransport it back or continue on your way!")
		transport_button.visible = true
		
	else:
		log_result("Not enough energy.")

func ss_batteries_install():
	if scrap_metal >= 1 and e_waste >= 4:
		scrap_metal -= 1
		e_waste -= 4
		update_resource_display()
		
		max_energy = 200
		update_energy_display()
		
		ss_batteries_installed = true
		update_tech_display()
		
		log_result("Installed Solid State Batteries!  Max energy increased!")

	else:
		log_result("Not enough resources.")

func pv_panel_install():
	if e_waste >= 2 and plastics >= 3:		
		e_waste -= 2
		plastics -= 3
		update_resource_display()
		
		energy_cost_explore = 5
		update_button_energy_cost()
		
		pv_panel_installed = true
		update_tech_display()
		
		log_result("Installed Photovoltaic Panels! Explore Cost decreased!")
		
	else:
		log_result("Not enough resources.")

func hd_lens_install():
	if scrap_metal >= 1 and plastics >= 4:
		scrap_metal -= 1
		plastics -= 4
		update_resource_display()
		
		energy_cost_search = 5
		update_button_energy_cost()
		
		hd_lens_installed = true
		update_tech_display()
		
		log_result("Installed High Definition Lens! Search Cost decreased!")
		
	else:
		log_result("Not enough resources.")

func qt_device_install():
	if scrap_metal >= 3 and plastics >= 2:
		scrap_metal -= 3
		plastics -= 2
		update_resource_display()
		
		energy_cost_transport = 5
		update_button_energy_cost()
		
		qt_device_installed = true
		update_tech_display()
		
		log_result("Installed Quantum Tunneling Device! Transport Cost decreased!")
		
	else:
		log_result("Not enough resources.")

func hf_sensor_install():
	if scrap_metal >= 2 and e_waste >= 3:
		scrap_metal -= 2
		e_waste -= 3
		update_resource_display()
		
		energy_cost_scan = 5
		update_button_energy_cost()
		
		hf_sensors_installed = true
		update_tech_display()
		
		log_result("Installed High Frequency Sensors! Scan Cost decreased!")

	else:
		log_result("Not enough resources.")

func he_laser_install():
	if e_waste >= 4 and plastics >= 1:
		e_waste -= 4
		plastics -= 1
		update_resource_display()
		
		energy_cost_salvage = 5
		update_button_energy_cost()
		
		he_laser_installed = true
		update_tech_display()
		
		log_result("Installed High Efficiency Laser! Salvage Cost decreased!")
		
	else:
		log_result("Not enough resources.")

func log_result(text: String):
	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_log.add_child(label)
	result_log.move_child(label, 0)

func clear_log():
	# Remove all log entries
	for child in result_log.get_children():
		child.queue_free()

	log_result("Log cleared.")  # Optionally add a message to indicate the log was cleared

func redeploy():
	energy = max_energy
	update_energy_display()

	# Increment redeploy count and output the message
	redeploy_count += 1
	log_result("Redeploying...Drone #" + str(redeploy_count).pad_zeros(6) + " online!")

	# Hide all action buttons except Redeploy and Explore
	redeploy_button.visible = true
	explore_button.visible = true
	search_button.visible = false
	salvage_button.visible = false
	transport_button.visible = false
	scan_button.visible = false

func save_game():
	var data = {
		"max_energy": max_energy,
		"energy": energy,
		"scrap_metal": scrap_metal,
		"e_waste": e_waste,
		"plastics": plastics,
		"found_resource": found_resource,
		"ss_batteries_unlocked": ss_batteries_unlocked,
		"ss_batteries_installed": ss_batteries_installed,
		"pv_panel_unlocked": pv_panel_unlocked,
		"pv_panel_installed": pv_panel_installed,
		"hd_lens_unlocked": hd_lens_unlocked,
		"hd_lens_installed": hd_lens_installed,
		"qt_device_unlocked": qt_device_unlocked,
		"qt_device_installed": qt_device_installed,
		"hf_sensors_unlocked": hf_sensors_unlocked,
		"hf_sensors_installed": hf_sensors_installed,
		"he_laser_unlocked": he_laser_unlocked,
		"he_laser_installed": he_laser_installed,
		"energy_cost_explore": energy_cost_explore,
		"energy_cost_search": energy_cost_search,
		"energy_cost_scan": energy_cost_scan,
		"energy_cost_salvage": energy_cost_salvage,
		"energy_cost_transport": energy_cost_transport,
		"redeploy_count": redeploy_count
	}
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	
	log_result("Game Saved!")

func load_game():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary:
			max_energy = data.get("max_energy", 100)
			energy = data.get("energy", max_energy)
			scrap_metal = data.get("scrap_metal", 0)
			e_waste = data.get("e_waste", 0)
			plastics = data.get("plastics", 0)
			found_resource = data.get("found_resource", "")
			
			ss_batteries_unlocked = data.get("ss_batteries_unlocked", false)
			ss_batteries_installed = data.get("ss_batteries_installed", false)
			pv_panel_unlocked = data.get("pv_panel_unlocked", false)
			pv_panel_installed = data.get("pv_panel_installed", false)
			hd_lens_unlocked = data.get("hd_lens_unlocked", false)
			hd_lens_installed = data.get("hd_lens_installed", false)
			qt_device_unlocked = data.get("qt_device_unlocked", false)
			qt_device_installed = data.get("qt_device_installed", false)
			hf_sensors_unlocked = data.get("hf_sensors_unlocked", false)
			hf_sensors_installed = data.get("hf_sensors_installed", false)
			he_laser_unlocked = data.get("he_laser_unlocked", false)
			he_laser_installed = data.get("he_laser_installed", false)
			
			energy_cost_explore = data.get("energy_cost_explore", 10)
			energy_cost_search = data.get("energy_cost_search", 10)
			energy_cost_scan = data.get("energy_cost_scan", 50)
			energy_cost_salvage = data.get("energy_cost_salvage", 50)
			energy_cost_transport = data.get("energy_cost_transport", 50)
			
			redeploy_count = data.get("redeploy_count", 0)

			# Update UI elements to reflect loaded values
			update_energy_display()
			update_resource_display()
			update_tech_display()
			update_button_energy_cost()
			
			log_result("Game Loaded!")
	else:
		log_result("No Save File Found!")

func reset_game():
	# Delete the save file if it exists
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	
	# Reload the current scene to reset everything
	get_tree().reload_current_scene()
