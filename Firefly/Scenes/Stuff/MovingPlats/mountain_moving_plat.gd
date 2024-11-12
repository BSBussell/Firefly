extends MovingPlat

@onready var magic_plat = $MagicPlat


func _ready():
	deactivate()


func _on_magic_plat_player_landed(player):
	activate()
	magic_plat.activate()


func _on_magic_plat_player_left(player):
	
	if player.velocity.y < player.jump_velocity:
		print(player.velocity.y)
		player.launched = true


func _on_cycle_finished():
	deactivate() 
	magic_plat.deactivate()  
