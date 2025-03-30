extends VBoxContainer
# Simple component to manage the result log display

# Maximum number of log entries to keep
const MAX_LOG_ENTRIES = 50

# Add a message to the log
func add_message(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Add at the top for most recent first
	add_child(label)
	move_child(label, 0)
	
	# Prune old messages if we exceed the limit
	_prune_old_messages()

# Clear all messages from the log
func clear() -> void:
	for child in get_children():
		child.queue_free()

# Remove oldest messages if we have too many
func _prune_old_messages() -> void:
	while get_child_count() > MAX_LOG_ENTRIES:
		var oldest = get_child(get_child_count() - 1)
		oldest.queue_free()
