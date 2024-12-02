extends MovingPlat

@export var flip_sprite: bool = false


@onready var magic_plat: Platform = $MagicPlat
@onready var moving_plat_trace = $MovingPlatTrace


var flyph: Flyph = null
var launched: bool = false

func child_ready():
	
	magic_plat.flip_sprite(flip_sprite)
	deactivate()


func _on_magic_plat_player_landed(player):
	
	
	flyph = player
	if not is_active():
		activate()
		magic_plat.activate()
			
		


func _on_magic_plat_player_left(player: Flyph):
	
	plat_launch(player)
	#if plat_launch(player):
		#launched = true
	
	flyph = null


func _on_cycle_finished():
	if not magic_plat.landed:
		deactivate() 
		magic_plat.deactivate()   
		
	launched = false
