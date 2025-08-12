extends Area2D

@export var musicPlayer: AudioStreamPlayer
@export var song: AudioStream

var entered: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	
	if not entered:
		var playback_position = musicPlayer.get_playback_position()
		musicPlayer.stream = song
		musicPlayer.play(playback_position)
