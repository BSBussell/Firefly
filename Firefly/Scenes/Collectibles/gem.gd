extends Node2D
class_name Gem

var consumed = false

# Collider
@onready var area_2d = $Area2D


@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var respawn_timer = $RespawnTimer

# FX
@onready var fx = $Animator

# SFX
@onready var pop = $pop
@onready var crash = $crash


# Called when the node enters the scene tree for the first time.
func _ready():
	animated_sprite_2d.play("Spin")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_body_entered(body):
	
	var player = body as Flyph
	if player:
		if not consumed:
			consume_item(player)
	pass # Replace with function body.


func consume_item(player: Flyph):

	consumed = true
	fx.play("Eat")
	crash.play()
	respawn_timer.start()
	area_2d.monitoring = false
	
	# Add 50 glow points
	player.add_glow(50)
	
	



func _on_respawn_timer_timeout():
	consumed = false
	fx.play("PopIn")
	pop.play()
	area_2d.monitoring = true
