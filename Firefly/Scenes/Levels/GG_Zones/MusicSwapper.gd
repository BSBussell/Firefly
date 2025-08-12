extends Area2D
class_name MusicArea2D

@export var enter_stream: AudioStream
@export var exit_stream: AudioStream
@export var music_player: AudioStreamPlayer



func _on_body_entered(body) -> void:
	var player: Flyph = body as Flyph
	if player:
		var scrobble: int = music_player.get_playback_position()
		music_player.stream = enter_stream
		music_player.play(scrobble)
		


func _on_body_exited(body) -> void:
	var player: Flyph = body as Flyph
	if player:
		var scrobble: int = music_player.get_playback_position()
		music_player.stream = exit_stream
		music_player.play(scrobble)
		
