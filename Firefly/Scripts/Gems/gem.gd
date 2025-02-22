extends Node2D
class_name Gem

@export var glow_points: int = 50

var active: bool = true
var consumed: bool  = false

# Collider
@onready var area_2d = $Area2D


@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var respawn_timer = $RespawnTimer

# FX
@onready var fx = $Animator

# SFX
@onready var pop = $pop
@onready var crash = $crash



func _on_area_2d_body_entered(body):
	
	if consumed or not active:
		return

	var player = body as Flyph
	if player:
		consume_item(player)
		
	pass # Replace with function body.


func consume_item(player: Flyph):

	consumed = true
	fx.play("Eat")
	crash.play()
	respawn_timer.start()
	area_2d.set_deferred("monitoring", false)
	
	# Add 50 glow points
	if player:
		player.add_glow(glow_points)
	
	

func respawn() -> void:
	consumed = false
	fx.play("PopIn")
	pop.play()
	area_2d.set_deferred("monitoring", true)
	

func _on_respawn_timer_timeout():
	respawn()


## Makes the gem visible and active
func activate():
	active = true
	
	animated_sprite_2d.play("Spin")
	
	# If it hasn't been consumed display it. otherwise just wait
	if not consumed: 
		animated_sprite_2d.visible = true
		
		# Play the pop in animation/sfx
		fx.play("PopIn")
		pop.play()
		
		# disable player detection
		area_2d.set_deferred("monitoring", true)
	
	

	

## Makes the gem invisible and inactive
func deactivate():
	active = false
	area_2d.set_deferred("monitoring", false)
	animated_sprite_2d.visible = false
	visible = false
