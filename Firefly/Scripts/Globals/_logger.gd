extends Node
class_name Logger

# Logging Settings
var log_calls = true

# Default Log File
var log_name = "user://fire_log.txt"

# How many log messages before the log file is saved
var log_save_size: int = 1

var _log_count: int = 0
var log_file: FileAccess

# Initialize the logger
func _ready():
	open_log_file()
	info("Logger Initialized")

# Open the log file
func open_log_file():
	log_file = FileAccess.open(log_name, FileAccess.WRITE_READ)
	if log_file == null:
		printerr("Failed to open log file.")
	else:
		log_file.seek_end(0)  # Move to the end for appending

# Log a message to the log file with a tick count
func log_message(message: String):
	if not log_calls:
		return

	var tick = Time.get_ticks_msec()
	var new_message = "[" + str(tick) + "] - " + message + "\n"

	if log_file != null:
		log_file.seek_end(0)
		log_file.store_string(new_message)
		_log_count += 1

		if _log_count >= log_save_size:
			log_file.flush()
			_log_count = 0

	else:
		printerr("Failed to write to log file.")

# Flush and close the log file on exit
func _exit_tree():
	if log_file != null:
		log_file.close()

# Convenience methods for different log levels
func debug(message: String):
	log_message("[DEBUG] - " + message)

func info(message: String):
	log_message("[INFO] - " + message)

func warning(message: String):
	log_message("[WARNING] - " + message)

func error(message: String):
	log_message("[ERROR] - " + message)

func log_context(context: String, message: String):
	log_message("[" + context + "] - " + message)