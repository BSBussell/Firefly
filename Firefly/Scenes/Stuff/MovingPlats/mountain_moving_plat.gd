extends MovingPlat

@onready var mtn_plat_3x = $mtn_plat_3x

func _ready():
	deactivate()

# Platform events
func _on_mtn_plat_3x_player_landed():
	activate()  

# Moving Plat events
func _on_cycle_finished():
	deactivate()


func _on_mtn_plat_3x_player_left():
	

	if _globals.ACTIVE_PLAYER.velocity.y < _globals.ACTIVE_PLAYER.jump_velocity:
		print(_globals.ACTIVE_PLAYER.velocity.y)
		_globals.ACTIVE_PLAYER.launched = true
