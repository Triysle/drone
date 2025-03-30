extends Node
# Main scene script - primarily initializes the game and managers

func _ready():
	# Game starts automatically when the managers are ready
	# Most functionality is delegated to the GameManager
	print("DRONE game initialized")
