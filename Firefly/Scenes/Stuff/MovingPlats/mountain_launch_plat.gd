extends MovingPlat

@export var flip_sprite: bool = false
@export var upward: bool = false


@onready var magic_plat: Platform = $MagicPlat
@onready var moving_plat_trace = $MovingPlatTrace


var flyph: Flyph = null
var launched: bool = false

func child_ready():
	
	magic_plat.flip_sprite(flip_sprite)
	
	if upward:
		magic_plat.prefix = "up_"
		magic_plat.deactivate()
		
		
	magic_plat.activate_audio.pitch_scale = 1.5
	deactivate()


func _on_magic_plat_player_landed(player):
	
	
	flyph = player
	if not is_active():
		activate()
		magic_plat.activate()
			
		


func _on_magic_plat_player_left(player: Flyph):
	
	
	if plat_launch(player):
		launched = true
	
	flyph = null


func _on_cycle_finished():
	
	deactivate() 
	magic_plat.deactivate()   
	launched = false
