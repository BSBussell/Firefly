extends LineEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_text_changed(new_text):
	 # Regex pattern for a-z, A-Z, and 1-9
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z1-9]")
	
	# Remove any characters that don't match the allowed pattern
	var filtered_text = regex.sub(new_text, "", true)
	
	# Update the text only if changes were made
	if filtered_text != new_text:
		self.text = filtered_text
