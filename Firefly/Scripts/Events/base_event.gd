# base_event.gd
extends Area2D

@export var one_shot = true
var executed = false
var entered = false
var enter_body: CollisionObject2D

func _on_body_entered(body):
	if executed and one_shot:
		return
	entered = true
	enter_body = body
	executed = true
	on_enter(body)

func _on_body_exited(body):
	entered = false
	on_exit(body)

# Override these functions in derived scripts for specific behavior
func on_enter(_body):
	pass

func on_exit(_body):
	pass
