extends Node

# Paths for the source and save folders
var source_folder_path: String = "res://Assets/Playtest Saves/saves/"
var save_folder_path: String = "user://saves/"

func _ready():
	
	return
	
	# Ensure the source and save folders exist
	ensure_folder_exists(source_folder_path)
	ensure_folder_exists(save_folder_path)

	# Sync files from the source folder to the save folder
	sync_playtest_files(source_folder_path, save_folder_path)

func ensure_folder_exists(folder_path: String):
	var dir = DirAccess.open(folder_path)
	if not dir:
		var parent_dir = DirAccess.open(folder_path.get_base_dir())
		if parent_dir:
			parent_dir.make_dir(folder_path.get_file())
			print("Created folder:", folder_path)
		else:
			print("Failed to access parent directory for:", folder_path)

func sync_playtest_files(source_path: String, target_path: String):
	var source_dir = DirAccess.open(source_path)
	if not source_dir:
		print("Source folder does not exist:", source_path)
		return

	var target_dir = DirAccess.open(target_path)
	if not target_dir:
		print("Target folder does not exist:", target_path)
		return

	# Iterate through the source folder
	source_dir.list_dir_begin()
	var file_name = source_dir.get_next()
	while file_name != "":
		# Skip directories
		if not source_dir.current_is_dir():
			var source_file_path = source_path + file_name
			var target_file_path = target_path + file_name

			# Copy the file if it doesn't exist in the target folder
			if not FileAccess.file_exists(target_file_path):
				var file = FileAccess.open(source_file_path, FileAccess.READ)
				if file:
					var file_data = file.get_buffer(file.get_length())
					file.close()

					var new_file = FileAccess.open(target_file_path, FileAccess.WRITE)
					new_file.store_buffer(file_data)
					new_file.close()

					print("Copied file:", source_file_path, "->", target_file_path)
				else:
					print("Failed to open source file:", source_file_path)
			else:
				print("File already exists:", target_file_path)

		file_name = source_dir.get_next()

	source_dir.list_dir_end()
