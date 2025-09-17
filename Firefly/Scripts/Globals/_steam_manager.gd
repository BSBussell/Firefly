extends Node
class_name Steam_Manager

## SteamManager: Handles Steamworks initialization for GodotSteam v4.12.
## Provides overlay helpers, auto-detects dev mode fallbacks, and keeps logging
## lightweight per project standards.

signal steam_ready
signal steam_failed(error_msg: String)
signal steam_overlay_toggled(active: bool)

const DEV_APPID_FILE: String = "res://steam_appid_dev.txt"
const RUNTIME_APPID_FILE: String = "steam_appid.txt"
const DEFAULT_DEV_APP_ID: int = 480
const DEFAULT_PRESENCE_STATUS: String = "In the forest ✨"
const PRESENCE_STATUS_KEY: String = "status"
const STEAM_SINGLETON: StringName = &"Steam"
const SIGNAL_OVERLAY_TOGGLED: StringName = &"steam_overlay_toggled"

const OVERLAY_DIALOG_FRIENDS: StringName = &"Friends"
const OVERLAY_DIALOG_COMMUNITY: StringName = &"Community"
const OVERLAY_DIALOG_SETTINGS: StringName = &"Settings"
const OVERLAY_DIALOG_PLAYERS: StringName = &"Players"
const OVERLAY_DIALOG_STATS: StringName = &"Stats"
const OVERLAY_DIALOG_ACHIEVEMENTS: StringName = &"Achievements"
const OVERLAY_DIALOG_OFFICIAL_GROUP: StringName = &"OfficialGameGroup"

var _steam: Object = null
var _initialized: bool = false
var _dev_mode_used: bool = false
var _overlay_active: bool = false
var _overlay_signal_connected: bool = false

class ProjectSettingsInfo:
	extends RefCounted

	var app_id: int = 0
	var auto_initialize: bool = false
	var embed_callbacks: bool = false

	func has_valid_app_id() -> bool:
		return app_id > 0



func _ready() -> void:
	
	if not Engine.has_singleton(STEAM_SINGLETON):
		push_warning("[Steam] Steam singleton not available. Running without Steam integration.")
		emit_signal("steam_failed", "Steamworks plugin not found.")
		return

	_steam = Engine.get_singleton(STEAM_SINGLETON)
	_connect_overlay_signals()

	var settings_info := _read_project_settings()
	if settings_info.auto_initialize:
		await get_tree().process_frame
		_initialized = _check_init_success()

	if not _initialized:
		_initialized = _attempt_explicit_init(settings_info)

	if not _initialized and _should_attempt_dev_mode() and _ensure_runtime_appid_file():
		_initialized = _try_init_steam()
		_dev_mode_used = _initialized

	
	if _initialized:
		set_process(true)
		_log_user()
		_set_presence_status(DEFAULT_PRESENCE_STATUS)
		emit_signal("steam_ready")

		# Position Steam's overlay notifications (toasts) in bottom-left.
		# Note: use Steam.POSITION_* constants, and call the methods on the Steam singleton.
		_steam.setOverlayNotificationPosition(Steam.POSITION_BOTTOM_LEFT)
		_steam.setOverlayNotificationInset(10, 10)  # inset from the corner (px)
	else:
		var error_message := "Steam failed to initialize. Is the Steam client running?"
		push_warning("[Steam] %s" % error_message)
		emit_signal("steam_failed", error_message)


func _process(_delta: float) -> void:
	if _steam == null or not _initialized:
		return
	_steam.run_callbacks()

func _unhandled_key_input(event: InputEvent) -> void:
	# Default behavior: let Steam client handle the overlay hotkey (configurable in Steam settings).
	pass
	

func is_ready() -> bool:
	return _initialized and _steam != null and _steam.loggedOn()

func open_overlay_store(app_id: int = 4002900) -> void:
	if is_ready():
		_steam.activateGameOverlayToStore(app_id, 0)

func open_overlay_url(url: String) -> void:
	if is_ready():
		_steam.activateGameOverlayToWebPage(url)

func open_overlay(dialog: StringName) -> void:
	_open_overlay_dialog(dialog)

func open_friends_overlay() -> void:
	_open_overlay_dialog(OVERLAY_DIALOG_FRIENDS)

func open_community_overlay() -> void:
	_open_overlay_dialog(OVERLAY_DIALOG_COMMUNITY)

func open_settings_overlay() -> void:
	_open_overlay_dialog(OVERLAY_DIALOG_SETTINGS)

func open_recent_players_overlay() -> void:
	_open_overlay_dialog(OVERLAY_DIALOG_PLAYERS)

func open_stats_overlay() -> void:
	_open_overlay_dialog(OVERLAY_DIALOG_STATS)

func open_achievements_overlay() -> void:
	_open_overlay_dialog(OVERLAY_DIALOG_ACHIEVEMENTS)

func open_official_group_overlay() -> void:
	_open_overlay_dialog(OVERLAY_DIALOG_OFFICIAL_GROUP)

func set_presence(key: String, value: String) -> void:
	if is_ready():
		_steam.setRichPresence(key, value)

func set_presence_status(text: String) -> void:
	_set_presence_status(text)

func is_overlay_active() -> bool:
	return _overlay_active

func _attempt_explicit_init(settings_info: ProjectSettingsInfo) -> bool:
	if settings_info.has_valid_app_id():
		return _try_init_with(settings_info.app_id, settings_info.embed_callbacks)
	return _try_init_steam()

func _try_init_with(app_id: int, embed_callbacks: bool) -> bool:
	if "steamInitEx" in _steam:
		var result: Variant = _steam.steamInitEx(app_id, embed_callbacks)
		return _interpret_init_result(result)
	elif "steamInit" in _steam:
		return _steam.steamInit(app_id, embed_callbacks)
	return _try_init_steam()

func _try_init_steam() -> bool:
	if "steamInitEx" in _steam:
		var result: Variant = _steam.steamInitEx()
		return _interpret_init_result(result)
	elif "steamInit" in _steam:
		return _steam.steamInit()
	return false

func _interpret_init_result(result: Variant) -> bool:
	if typeof(result) == TYPE_DICTIONARY:
		return int(result.get("status", 1)) == 0
	return bool(result)

func _check_init_success() -> bool:
	if "get_steam_init_result" in _steam:
		var result: Dictionary = _steam.get_steam_init_result()
		return int(result.get("status", 1)) == 0
	return _steam.loggedOn()

func _read_project_settings() -> ProjectSettingsInfo:
	var info := ProjectSettingsInfo.new()
	info.app_id = _get_ps_int([
		"steam/initialization/app_id",
		"steam/init/app_id",
		"application/steam/app_id",
		"steam/app_id"
	])
	info.auto_initialize = _get_ps_bool([
		"steam/initialization/auto_initialize",
		"steam/auto_initialize"
	])
	info.embed_callbacks = _get_ps_bool([
		"steam/initialization/embed_callbacks",
		"steam/embed_callbacks"
	])
	return info

func _get_ps_bool(keys: Array[String]) -> bool:
	for key in keys:
		if ProjectSettings.has_setting(key):
			return bool(ProjectSettings.get_setting(key))
	return false

func _get_ps_int(keys: Array[String]) -> int:
	for key in keys:
		if ProjectSettings.has_setting(key):
			return int(ProjectSettings.get_setting(key))
	return 0

func _should_attempt_dev_mode() -> bool:
	return Engine.is_editor_hint() or OS.is_debug_build()

func _ensure_runtime_appid_file() -> bool:
	var app_id_text := str(DEFAULT_DEV_APP_ID)
	if FileAccess.file_exists(DEV_APPID_FILE):
		var file: FileAccess = FileAccess.open(DEV_APPID_FILE, FileAccess.READ)
		if file:
			app_id_text = file.get_as_text().strip_edges()
			file.close()
	var output_path := _project_root_join(RUNTIME_APPID_FILE)
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	if output == null:
		push_warning("[Steam] Could not write %s" % output_path)
		return false
	output.store_string(app_id_text)
	output.flush()
	output.close()
	print("[Steam] Wrote %s with App ID %s for dev run." % [RUNTIME_APPID_FILE, app_id_text])
	return true

func _project_root_join(filename: String) -> String:
	var root_abs := ProjectSettings.globalize_path("res://")
	if not root_abs.ends_with("/"):
		root_abs += "/"
	return root_abs + filename

func _log_user() -> void:
	if not is_ready():
		push_warning("[Steam] Steam not initialized.")
		return
	var suffix := " [dev appid]" if _dev_mode_used else ""
	var message := "Logged in as %s (%s)%s" % [
		_steam.getPersonaName(),
		_steam.getSteamID(),
		suffix
	]
	print("[Steam] %s" % message)

func _set_presence_status(text: String) -> void:
	if is_ready():
		_steam.setRichPresence(PRESENCE_STATUS_KEY, text)

func _open_overlay_dialog(dialog: StringName) -> void:
	if not is_ready():
		return
	_steam.activateGameOverlay(str(dialog))

func _connect_overlay_signals() -> void:
	if _steam == null or _overlay_signal_connected:
		return
	if not _steam.has_signal(SIGNAL_OVERLAY_TOGGLED):
		return
	var err := _steam.connect(SIGNAL_OVERLAY_TOGGLED, Callable(self, "_on_overlay_toggled"))
	if err == OK:
		_overlay_signal_connected = true
	else:
		push_warning("[Steam] Failed to connect overlay signal. Error %s" % err)

func _on_overlay_toggled(active: bool) -> void:
	_overlay_active = active
	emit_signal("steam_overlay_toggled", active)
