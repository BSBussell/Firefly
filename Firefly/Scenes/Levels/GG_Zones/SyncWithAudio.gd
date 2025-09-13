extends AudioStreamPlayer2D
# This node = the positional MELODY source.

@export var backing: AudioStreamPlayer      # omnipresent backing player
@export var auto_start := true              # start on _ready, or call start_music() yourself

@export var MAX_DRIFT: float = 0.010    # seconds; ~10 ms is psychoacoustically invisible
@export var RESYNC_EVERY: float = 5.0   # periodic sanity check to kill long-session creep

var _since_resync := 0.0

func _ready() -> void:
	_harmonize_loop_settings()
	if auto_start:
		start_music()

func _harmonize_loop_settings() -> void:
	_force_loop(backing)
	_force_loop(self)

func _force_loop(p: Object) -> void:
	if p and p is AudioStreamPlayer and p.stream:
		var s = p.stream
		# Make loop behavior explicit; different stream types expose it differently.
		if s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif s is AudioStreamOggVorbis:
			s.loop = true
		elif "loop" in s:
			s.loop = true

func start_music() -> void:
	if not backing or not backing.stream or not stream:
		push_warning("Missing stream(s): assign backing + melody streams.")
		return

	# Reset both to sample 0
	backing.stop()
	stop()
	backing.seek(0.0)
	seek(0.0)

	# Launch backing first, then start melody at the EXACT same playback time
	backing.play(0.0)
	await get_tree().process_frame  # let audio server advance its clock this frame
	var t := backing.get_playback_position()
	play(t)

	_since_resync = 0.0

func _process(delta: float) -> void:
	if not (backing and backing.playing and playing):
		return
	_since_resync += delta
	if _since_resync >= RESYNC_EVERY:
		_since_resync = 0.0
		var t_back := backing.get_playback_position()
		var t_mel  := get_playback_position()
		if absf(t_back - t_mel) > MAX_DRIFT:
			seek(t_back)  # snap melody to backing

func set_music_paused(paused: bool) -> void:
	# Keep pause/resume in lockstep
	if backing: backing.stream_paused = paused
	stream_paused = paused

func restart_music() -> void:
	start_music()
