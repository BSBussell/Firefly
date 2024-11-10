extends MovingPlat


func _ready():
	deactivate()

# Platform events
func _on_mtn_plat_3x_player_landed():
	activate()  

# Moving Plat events
func _on_cycle_finished():
	deactivate()
